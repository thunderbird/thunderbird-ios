// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import IMAP
import NIOCore
import NIOEmbedded
import NIOIMAP
import Testing

struct AuthenticateCommandTests {
    //Expect: Name the command after the user who is signing in.
    //Case: When the command is created for a credential.
    @Test func name_namesUser_whenCommandIsCreated() {
        // Arrange
        let input: AuthenticateCommand = AuthenticateCommand(.xoauth2("user@example.com", token: "t0k3n"))

        // Act
        let actual = input.name

        // Assert
        #expect(actual == "authenticate \"user@example.com\"")
    }

    //Expect: Leave the token or password out of the name.
    //Case: When the command carries a credential, for each mechanism. The name ends up in logs and in
    //  `IMAPError.commandFailed`.
    @Test(arguments: [
        (Authentication.oauthbearer("user@example.com", token: "t0k3n"), "t0k3n"),
        (Authentication.plain("user@example.com", password: "pa55w0rd"), "pa55w0rd"),
        (Authentication.xoauth2("user@example.com", token: "t0k3n"), "t0k3n")
    ])
    func name_omitsCredential_whenCommandCarriesCredential(_ input: Authentication, _ secret: String) {
        // Act
        let actual = AuthenticateCommand(input).name.contains(secret)

        // Assert
        #expect(actual == false)
    }
}

// Each test below scripts the server's half of an `AUTHENTICATE` exchange and checks one thing about the client's
// half. `C:` and `S:` in the comments mark what the client and the server send.
//
// Nothing here touches the network. `Exchange` (at the bottom of this file) runs the same two handlers that
// `IMAPClient` puts on a real connection, so the bytes checked here are the bytes a server would see.
struct AuthenticateHandlerTests {
    // The failed exchange in Google's XOAUTH2 protocol document, with its example user, token and error challenge:
    // https://developers.google.com/workspace/gmail/imap/xoauth2-protocol
    //
    //   C: A01 AUTHENTICATE XOAUTH2 dXNlcj1zb21ldXNlckBleGFtcGxlLmNvbQFhdXRoPUJlYXJlciB5YTI5…
    //   S: + eyJzdGF0dXMiOiI0MDEiLCJzY2hlbWVzIjoiYmVhcmVyIG1hYyIsInNjb3BlIjoiaHR0cHM6Ly9tYWlsLmdvb2dsZS5jb20vIn0K
    //   C:
    //   S: A01 NO SASL authentication failed
    //
    // This is the scenario that used to hang: the server sends a challenge and waits, and nothing answered it.
    private static let googleCredential: Authentication = .xoauth2("someuser@example.com", token: "ya29.vF9dft4qmTc2Nvb3RlckBhdHRhdmlzdGEuY29tCg")
    private static let googleChallenge: String = "eyJzdGF0dXMiOiI0MDEiLCJzY2hlbWVzIjoiYmVhcmVyIG1hYyIsInNjb3BlIjoiaHR0cHM6Ly9tYWlsLmdvb2dsZS5jb20vIn0K"
    private static let googleErrorResult: String = #"{"status":"401","schemes":"bearer mac","scope":"https://mail.google.com/"}"# + "\n"

    // The failed exchange in RFC 7628, section 4.3, with its error challenge:
    // https://www.rfc-editor.org/rfc/rfc7628#section-4.3
    //
    //   C: A01 AUTHENTICATE OAUTHBEARER bixhPXVzZXJAZXhhbXBsZS5jb20s…
    //   S: + eyJzdGF0dXMiOiJpbnZhbGlkX3Rva2VuIiwic2NvcGUiOiJleGFtcGxlX3Njb3BlIi…
    //   C: AQ==
    //   S: A01 NO SASL authentication failed
    private static let rfcCredential: Authentication = .oauthbearer("user@example.com", token: "t0k3n")
    private static let rfcChallenge: String =
        "eyJzdGF0dXMiOiJpbnZhbGlkX3Rva2VuIiwic2NvcGUiOiJleGFtcGxlX3Njb3BlIiwib3BlbmlkLWNvbmZpZ3VyYXRpb24iOiJodHRwczovL2V4YW1wbGUuY29tLy53ZWxsLWtub3duL29wZW5pZC1jb25maWd1cmF0aW9uIn0="
    private static let rfcErrorResult: String = #"{"status":"invalid_token","scope":"example_scope","openid-configuration":"https://example.com/.well-known/openid-configuration"}"#

    // MARK: Rejected credential

    //Expect: Send the command line from Google's document, with the credential as the initial response (RFC 4959).
    //Case: When signing in with XOAUTH2 as the document's example user. The expected base64 is the document's own,
    //  so this pins our encoding to Google's.
    @Test func authenticate_sendsDocumentedCommand_whenCredentialIsGoogleExample() throws {
        // Arrange
        let expected = "A01 AUTHENTICATE XOAUTH2 dXNlcj1zb21ldXNlckBleGFtcGxlLmNvbQFhdXRoPUJlYXJlciB5YTI5LnZGOWRmdDRxbVRjMk52YjNSbGNrQmhkSFJoZG1semRHRXVZMjl0Q2cBAQ==\r\n"

        // Act
        let exchange: Exchange = try Exchange(Self.googleCredential)
        let actual = try exchange.sent()

        // Assert
        #expect(actual == expected)
    }

    //Expect: Send the command with the credential as the initial response, without `host` and `port`.
    //Case: When signing in with OAUTHBEARER. The RFC's example also sends the optional `host` and `port` pairs,
    //  which this client leaves out, so the expected response is built here and not copied from the RFC.
    @Test func authenticate_sendsInitialResponseWithoutHostAndPort_whenMechanismIsOAuthBearer() throws {
        // Arrange
        let initialResponse = Data("n,a=user@example.com,\u{01}auth=Bearer t0k3n\u{01}\u{01}".utf8).base64EncodedString()
        let expected = "A01 AUTHENTICATE OAUTHBEARER \(initialResponse)\r\n"

        // Act
        let exchange: Exchange = try Exchange(Self.rfcCredential)
        let actual = try exchange.sent()

        // Assert
        #expect(actual == expected)
    }

    //Expect: Answer the challenge with what the mechanism requires.
    //Case: When the server rejects the token and says why in a challenge.
    //  XOAUTH2: "The client sends an empty response ("\r\n") to the challenge containing the error message."
    //  OAUTHBEARER: "The client responds with the required dummy response; "AQ==" is the base64 encoding of the
    //  ASCII value 0x01." An empty line is not a valid answer there.
    @Test(arguments: [
        (googleCredential, googleChallenge, "\r\n"),
        (rfcCredential, rfcChallenge, "AQ==\r\n")
    ])
    func authenticate_answersChallenge_whenServerSendsErrorChallenge(_ credential: Authentication, _ challenge: String, _ expected: String) throws {
        // Arrange
        let exchange: Exchange = try Exchange(credential)
        try exchange.discardSent()

        // Act
        try exchange.receive("+ \(challenge)")
        let actual = try exchange.sent()

        // Assert
        #expect(actual == expected)
    }

    //Expect: Keep the command running.
    //Case: When the server has sent its error challenge but not yet the tagged response. The challenge explains
    //  the failure; only the tagged response ends the command.
    @Test(arguments: [
        (googleCredential, googleChallenge),
        (rfcCredential, rfcChallenge)
    ])
    func authenticate_doesNotEnd_whenServerHasOnlySentChallenge(_ credential: Authentication, _ challenge: String) throws {
        // Arrange
        let exchange: Exchange = try Exchange(credential)

        // Act
        try exchange.receive("+ \(challenge)")
        let actual = exchange.outcome

        // Assert
        #expect(actual == nil)
    }

    //Expect: Fail with the server's text and the reason it gave in the challenge.
    //Case: When the server ends the command with a tagged NO after its error challenge has been answered.
    @Test(arguments: [
        (googleCredential, googleChallenge, googleErrorResult),
        (rfcCredential, rfcChallenge, rfcErrorResult)
    ])
    func authenticate_failsWithServerTextAndReason_whenTokenIsRejected(_ credential: Authentication, _ challenge: String, _ errorResult: String) throws {
        // Arrange
        let exchange: Exchange = try Exchange(credential)
        let expected: Rejection = Rejection(text: "SASL authentication failed", failure: AuthenticationFailure(ByteBuffer(string: errorResult)))

        // Act
        try exchange.receive("+ \(challenge)")
        try exchange.receive("A01 NO SASL authentication failed")
        let actual = exchange.rejection

        // Assert
        #expect(actual == expected)
    }

    //Expect: Fail with the server's text and no reason.
    //Case: When the server skips the challenge and goes straight to NO. RFC 5530 gives it response codes to say
    //  why. PLAIN has no challenge step at all (RFC 4616), so a wrong password always ends this way.
    @Test(arguments: [
        (Authentication.xoauth2("user@example.com", token: "t0k3n"), "Invalid credentials (Failure)"),
        (Authentication.plain("user@example.com", password: "pa55w0rd"), "Authentication failed")
    ])
    func authenticate_failsWithServerText_whenServerRejectsWithoutChallenge(_ credential: Authentication, _ text: String) throws {
        // Arrange
        let exchange: Exchange = try Exchange(credential)
        let expected: Rejection = Rejection(text: text, failure: nil)

        // Act
        try exchange.receive("A01 NO [AUTHENTICATIONFAILED] \(text)")
        let actual = exchange.rejection

        // Assert
        #expect(actual == expected)
    }

    //Expect: Send nothing further.
    //Case: When the server rejects the credential without a challenge, so there is nothing to answer.
    @Test func authenticate_sendsNothingFurther_whenServerRejectsWithoutChallenge() throws {
        // Arrange
        let exchange: Exchange = try Exchange(.xoauth2("user@example.com", token: "t0k3n"))
        try exchange.discardSent()

        // Act
        try exchange.receive("A01 NO [AUTHENTICATIONFAILED] Invalid credentials (Failure)")
        let actual = try exchange.sent()

        // Assert
        #expect(actual == "")
    }

    // MARK: Challenges that aren't an OAuth error result

    //Expect: Answer the challenge all the same.
    //Case: When the challenge isn't an error result: text that isn't JSON, or no data at all, which is how a server
    //  prompts for a response it hasn't been given (RFC 4959, section 3). Whatever the challenge says, the server
    //  is waiting. Note the space after the "+" of the empty challenge: it is part of the syntax.
    @Test(arguments: [
        (Authentication.xoauth2("user@example.com", token: "t0k3n"), "+ bm90IGpzb24=", "\r\n"),  // "not json"
        (Authentication.oauthbearer("user@example.com", token: "t0k3n"), "+ ", "AQ==\r\n")
    ])
    func authenticate_answersChallenge_whenChallengeIsNotAnErrorResult(_ credential: Authentication, _ challenge: String, _ expected: String) throws {
        // Arrange
        let exchange: Exchange = try Exchange(credential)
        try exchange.discardSent()

        // Act
        try exchange.receive(challenge)
        let actual = try exchange.sent()

        // Assert
        #expect(actual == expected)
    }

    //Expect: Fail as a rejected credential, without a reason.
    //Case: When the challenge before the tagged NO wasn't an error result. Only the detail is lost.
    @Test(arguments: [
        (Authentication.xoauth2("user@example.com", token: "t0k3n"), "+ bm90IGpzb24="),  // "not json"
        (Authentication.oauthbearer("user@example.com", token: "t0k3n"), "+ ")
    ])
    func authenticate_failsWithoutReason_whenChallengeIsNotAnErrorResult(_ credential: Authentication, _ challenge: String) throws {
        // Arrange
        let exchange: Exchange = try Exchange(credential)
        let expected: Rejection = Rejection(text: "SASL authentication failed", failure: nil)

        // Act
        try exchange.receive(challenge)
        try exchange.receive("A01 NO SASL authentication failed")
        let actual = exchange.rejection

        // Assert
        #expect(actual == expected)
    }

    //Expect: Answer each challenge once.
    //Case: When the server sends two challenges before its tagged response.
    @Test func authenticate_answersEachChallengeOnce_whenServerSendsTwoChallenges() throws {
        // Arrange
        let exchange: Exchange = try Exchange(Self.googleCredential)
        try exchange.discardSent()

        // Act
        try exchange.receive("+ \(Self.googleChallenge)")
        let first = try exchange.sent()
        try exchange.receive("+ ")
        let second = try exchange.sent()
        let actual = [first, second]

        // Assert
        #expect(actual == ["\r\n", "\r\n"])
    }

    //Expect: Report the reason the first challenge gave.
    //Case: When a later challenge carries no reason. It must not erase the earlier one.
    @Test func authenticate_keepsEarlierReason_whenLaterChallengeHasNone() throws {
        // Arrange
        let exchange: Exchange = try Exchange(Self.googleCredential)

        // Act
        try exchange.receive("+ \(Self.googleChallenge)")
        try exchange.receive("+ ")
        try exchange.receive("A01 NO SASL authentication failed")
        let actual = exchange.rejection?.failure?.status

        // Assert
        #expect(actual == "401")
    }

    // MARK: Accepted credential

    //Expect: Keep the command running.
    //Case: When the server has sent an untagged CAPABILITY response but not yet the tagged OK. Untagged data
    //  doesn't end the command.
    @Test func authenticate_doesNotEnd_whenServerHasOnlySentUntaggedResponse() throws {
        // Arrange
        let exchange: Exchange = try Exchange(.xoauth2("user@example.com", token: "t0k3n"))

        // Act
        try exchange.receive("* CAPABILITY IMAP4rev1 IDLE NAMESPACE")
        let actual = exchange.outcome

        // Assert
        #expect(actual == nil)
    }

    //Expect: Report every capability the server announced.
    //Case: When the server accepts the token and announces three capabilities before the tagged OK.
    @Test func authenticate_collectsEveryCapability_whenServerAnnouncesCapabilities() throws {
        // Arrange
        let exchange: Exchange = try Exchange(.xoauth2("user@example.com", token: "t0k3n"))

        // Act
        try exchange.receive("* CAPABILITY IMAP4rev1 IDLE NAMESPACE")
        try exchange.receive("A01 OK Success")
        let actual = exchange.capabilities?.count

        // Assert
        #expect(actual == 3)
    }

    //Expect: Send nothing further.
    //Case: When the server accepts the token. The happy path has no challenge, so nothing extra is written.
    @Test func authenticate_sendsNothingFurther_whenServerAcceptsToken() throws {
        // Arrange
        let exchange: Exchange = try Exchange(.xoauth2("user@example.com", token: "t0k3n"))
        try exchange.discardSent()

        // Act
        try exchange.receive("* CAPABILITY IMAP4rev1 IDLE NAMESPACE")
        try exchange.receive("A01 OK Success")
        let actual = try exchange.sent()

        // Assert
        #expect(actual == "")
    }

    //Expect: Succeed with no capabilities.
    //Case: When the server accepts the token without announcing capabilities. Not every server does.
    @Test func authenticate_succeedsWithNoCapabilities_whenServerAnnouncesNone() throws {
        // Arrange
        let exchange: Exchange = try Exchange(.oauthbearer("user@example.com", token: "t0k3n"))

        // Act
        try exchange.receive("A01 OK Success")
        let actual = exchange.capabilities

        // Assert
        #expect(actual == [])
    }

    // MARK: Protocol errors

    //Expect: Fail as a command failure, not as a rejected credential.
    //Case: When the server answers BAD, which means the command itself was at fault ("command unknown or arguments
    //  invalid, authentication exchange cancelled", RFC 3501, section 6.2.2). It says nothing about the credential,
    //  and reporting a rejection would send the account layer off to refresh a token that may be perfectly good.
    @Test func authenticate_failsAsCommandFailure_whenServerAnswersBAD() throws {
        // Arrange
        let exchange: Exchange = try Exchange(.xoauth2("user@example.com", token: "t0k3n"))
        let expected: IMAPError = .commandFailed("Invalid SASL argument")

        // Act
        try exchange.receive("A01 BAD Invalid SASL argument")
        let actual = exchange.error

        // Assert
        #expect(actual == expected)
    }

    // MARK: Connection state

    //Expect: Write the next command.
    //Case: When a rejected exchange has ended. An unanswered challenge leaves NIOIMAP's state machine unable to take
    //  another command: it traps on one written before the server's tagged response, and refuses every one written
    //  after it (`InvalidClientState`). So the answer isn't only about speed: it is what returns the connection to
    //  a state where the next command can be written at all.
    @Test func send_writesNextCommand_whenRejectedExchangeHasEnded() throws {
        // Arrange
        let exchange: Exchange = try Exchange(Self.googleCredential)
        try exchange.receive("+ \(Self.googleChallenge)")
        try exchange.receive("A01 NO SASL authentication failed")
        try exchange.discardSent()

        // Act
        try exchange.send(CapabilityCommand().tagged("A02"))
        let actual = try exchange.sent()

        // Assert
        #expect(actual == "A02 CAPABILITY\r\n")
    }
}

// Sign-in exchanges shared with another Thunderbird client, using the same user name, token and server lines.
// Each test has a `//Source:` line linking to the test it was taken from.
//
// The source tests run against a mock server over a socket and start from the greeting. These start at the
// `AUTHENTICATE` command, which is where this client's OAuth-specific behavior begins, and use tag `A01` where
// the source connection uses `2`.
//
// Source cases with nothing here to test against are listed at the end of the suite.
struct AuthenticateExchangeTests {
    // USERNAME and XOAUTH_TOKEN in the source test
    private static let user: String = "user"
    private static let token: String = "token"

    // XOAUTH_STRING and OAUTHBEARER_STRING in the source test: the initial responses, base64-encoded
    private static let xoauth2String: String = Data("user=user\u{01}auth=Bearer token\u{01}\u{01}".utf8).base64EncodedString()
    private static let oauthBearerString: String = Data("n,a=user,\u{01}auth=Bearer token\u{01}\u{01}".utf8).base64EncodedString()

    // MARK: Accepted token

    //Expect: Send `AUTHENTICATE OAUTHBEARER` with the initial response on the same line.
    //Case: When signing in with OAUTHBEARER.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L312
    @Test func authenticate_sendsInitialResponseWithCommand_whenMechanismIsOAuthBearer() throws {
        // Arrange
        let expected = "A01 AUTHENTICATE OAUTHBEARER \(Self.oauthBearerString)\r\n"

        // Act
        let exchange: Exchange = try Exchange(.oauthbearer(Self.user, token: Self.token))
        let actual = try exchange.sent()

        // Assert
        #expect(actual == expected)
    }

    //Expect: Succeed.
    //Case: When the server answers an OAUTHBEARER sign-in with a tagged OK.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L312
    @Test func authenticate_succeeds_whenServerAcceptsOAuthBearerToken() throws {
        // Arrange
        let exchange: Exchange = try Exchange(.oauthbearer(Self.user, token: Self.token))

        // Act
        try exchange.receive("A01 OK Success")
        let actual = exchange.capabilities

        // Assert
        #expect(actual != nil)
    }

    //Expect: Send `AUTHENTICATE XOAUTH2` with the initial response on the same line.
    //Case: When signing in with XOAUTH2.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L344
    @Test func authenticate_sendsInitialResponseWithCommand_whenMechanismIsXOAuth2() throws {
        // Arrange
        let expected = "A01 AUTHENTICATE XOAUTH2 \(Self.xoauth2String)\r\n"

        // Act
        let exchange: Exchange = try Exchange(.xoauth2(Self.user, token: Self.token))
        let actual = try exchange.sent()

        // Assert
        #expect(actual == expected)
    }

    //Expect: Succeed.
    //Case: When the server answers an XOAUTH2 sign-in with a tagged OK.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L344
    @Test func authenticate_succeeds_whenServerAcceptsXOAuth2Token() throws {
        // Arrange
        let exchange: Exchange = try Exchange(.xoauth2(Self.user, token: Self.token))

        // Act
        try exchange.receive("A01 OK Success")
        let actual = exchange.capabilities

        // Assert
        #expect(actual != nil)
    }

    //Expect: Report the capabilities the server announced.
    //Case: When the server sends an untagged CAPABILITY response before the tagged OK, as Gmail does.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L360
    @Test func authenticate_collectsCapabilities_whenServerSendsUntaggedCapabilityResponse() throws {
        // Arrange
        let exchange: Exchange = try Exchange(.xoauth2(Self.user, token: Self.token))

        // Act
        try exchange.receive("* CAPABILITY IMAP4rev1 X-GM-EXT-1")
        try exchange.receive("A01 OK Success")
        let actual = exchange.capabilities?.contains(.gmailExtensions)

        // Assert
        #expect(actual == true)
    }

    //Expect: Report the capabilities the server announced.
    //Case: When the server puts the capability list in a response code of the tagged OK and sends no untagged
    //  CAPABILITY response.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L513
    @Test func authenticate_collectsCapabilities_whenOKCarriesCapabilityResponseCode() throws {
        // Arrange
        let exchange: Exchange = try Exchange(.xoauth2(Self.user, token: Self.token))

        // Act
        try exchange.receive("A01 OK [CAPABILITY IMAP4REV1 IDLE XM-GM-EXT-1]")
        let actual = exchange.capabilities?.map(\.rawValue).contains("XM-GM-EXT-1")

        // Assert
        #expect(actual == true)
    }

    // MARK: Rejected token

    //Expect: Answer the challenge with an empty line.
    //Case: When an XOAUTH2 server rejects the token and says why in a challenge. The first four challenges are
    //  the shared test payloads; the last two are the unreadable challenges of the retry test.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L410
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L428
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L448
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L469
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L490
    //  In each source test the client sends an empty line after the challenge.
    @Test(arguments: [
        XOAuth2ChallengeTestData.encoded(XOAuth2ChallengeTestData.status401Response),
        XOAuth2ChallengeTestData.encoded(XOAuth2ChallengeTestData.status400Response),
        XOAuth2ChallengeTestData.encoded(XOAuth2ChallengeTestData.invalidResponse),
        XOAuth2ChallengeTestData.encoded(XOAuth2ChallengeTestData.missingStatusResponse),
        "r3j3krj3irj3oir3ojo",
        "433ba3a3a"
    ])
    func authenticate_answersWithEmptyLine_whenXOAuth2ServerSendsErrorChallenge(_ challenge: String) throws {
        // Arrange
        let exchange: Exchange = try Exchange(.xoauth2(Self.user, token: Self.token))
        try exchange.discardSent()

        // Act
        try exchange.receive("+ \(challenge)")
        let actual = try exchange.sent()

        // Assert
        #expect(actual == "\r\n")
    }

    //Expect: Fail with the text of the server's NO response.
    //Case: When an XOAUTH2 server rejects the token with status 401.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L410
    //  The source test expects the failure to carry the server text `SASL authentication failed`.
    @Test func authenticate_failsWithServerText_whenXOAuth2TokenIsRejected() throws {
        // Arrange
        let exchange: Exchange = try Exchange(.xoauth2(Self.user, token: Self.token))

        // Act
        try exchange.receive("+ \(XOAuth2ChallengeTestData.encoded(XOAuth2ChallengeTestData.status401Response))")
        try exchange.receive("A01 NO SASL authentication failed")
        let actual = exchange.rejection?.text

        // Assert
        #expect(actual == "SASL authentication failed")
    }

    //Expect: Report the status the server gave.
    //Case: When the challenge is the shared `STATUS_401_RESPONSE` or `STATUS_400_RESPONSE` payload.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L410
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L428
    //  The source client acts on the status itself (400 means retry); this client hands it to the caller.
    @Test(arguments: [
        (XOAuth2ChallengeTestData.status401Response, "401"),
        (XOAuth2ChallengeTestData.status400Response, "400")
    ])
    func authenticate_reportsStatus_whenXOAuth2ChallengeHasStatus(_ response: String, _ expected: String) throws {
        // Arrange
        let exchange: Exchange = try Exchange(.xoauth2(Self.user, token: Self.token))

        // Act
        try exchange.receive("+ \(XOAuth2ChallengeTestData.encoded(response))")
        try exchange.receive("A01 NO SASL authentication failed")
        let actual = exchange.rejection?.failure?.status

        // Assert
        #expect(actual == expected)
    }

    //Expect: Fail as a rejected credential, without a reason.
    //Case: When the challenge can't be read as an error result: invalid JSON, JSON without a status, or text that
    //  isn't base64 at all.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L448
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L469
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L490
    @Test(arguments: [
        XOAuth2ChallengeTestData.encoded(XOAuth2ChallengeTestData.invalidResponse),
        XOAuth2ChallengeTestData.encoded(XOAuth2ChallengeTestData.missingStatusResponse),
        "r3j3krj3irj3oir3ojo",
        "433ba3a3a"
    ])
    func authenticate_failsWithoutReason_whenXOAuth2ChallengeCannotBeDecoded(_ challenge: String) throws {
        // Arrange
        let exchange: Exchange = try Exchange(.xoauth2(Self.user, token: Self.token))
        let expected: Rejection = Rejection(text: "SASL authentication failed", failure: nil)

        // Act
        try exchange.receive("+ \(challenge)")
        try exchange.receive("A01 NO SASL authentication failed")
        let actual = exchange.rejection

        // Assert
        #expect(actual == expected)
    }

    // MARK: Encoded user names
    // The source tests check each response as text and as base64. The text is checked in `AuthenticationTests`;
    // the base64 is checked here, against the source's expected strings, so a match means both clients put the same
    // bytes on the wire.

    //Expect: Send the same base64 as the source test expects.
    //Case: When an OAUTHBEARER user name needs no encoding, contains `=`, or contains `,`.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/legacy/core/src/test/java/com/fsck/k9/sasl/OAuthBearerTest.kt#L10
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/legacy/core/src/test/java/com/fsck/k9/sasl/OAuthBearerTest.kt#L22
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/legacy/core/src/test/java/com/fsck/k9/sasl/OAuthBearerTest.kt#L34
    @Test(arguments: [
        ("user@domain.example", "bixhPXVzZXJAZG9tYWluLmV4YW1wbGUsAWF1dGg9QmVhcmVyIHRva2VuAQE="),
        ("user=name@domain.example", "bixhPXVzZXI9M0RuYW1lQGRvbWFpbi5leGFtcGxlLAFhdXRoPUJlYXJlciB0b2tlbgEB"),
        ("user,name", "bixhPXVzZXI9MkNuYW1lLAFhdXRoPUJlYXJlciB0b2tlbgEB")
    ])
    func authenticate_sendsSameInitialResponseAsSource_whenMechanismIsOAuthBearer(_ user: String, _ expected: String) throws {
        // Arrange
        let input: Authentication = .oauthbearer(user, token: "token")

        // Act
        let exchange: Exchange = try Exchange(input)
        let actual = try exchange.sent()

        // Assert
        #expect(actual == "A01 AUTHENTICATE OAUTHBEARER \(expected)\r\n")
    }

    // Source cases that are not here, because this client has nothing for them to test:
    //
    // - https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L328
    //   The source client picks OAUTHBEARER when a server offers both mechanisms. Here the caller picks the
    //   mechanism, and the account layer always picks XOAUTH2.
    // - https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L378
    //   The source client refuses to sign in without SASL-IR. `IMAPClient.authenticate` doesn't check it for the
    //   OAuth mechanisms.
    // - The retry halves of the 400, invalid JSON, missing status and retry-fails cases linked above: the source
    //   client asks its token provider for a new token and tries once more. `IMAPClient` has no token provider; it
    //   reports the rejection and stops. The server's half of those exchanges, up to the first NO, is covered above.
    // - After a sign-in that announced no capabilities, the source client sends CAPABILITY. `IMAPClient` doesn't.
    //
    // `open() AUTH OAUTHBEARER with AUTH=OAUTHBEARER capability missing` is in `IMAPClientTests`, since the check
    // is made by `IMAPClient` before the command is sent.
}

// `Capability` is spelled `IMAP.Capability` in this file because NIOIMAP, imported here to build the pipeline, has a
// type of the same name.

/// What a rejected `AUTHENTICATE` reports: the associated values of `IMAPError.authenticationFailed`.
private struct Rejection: Equatable {
    let text: String
    let failure: AuthenticationFailure?
}

/// One `AUTHENTICATE` exchange against a scripted server.
///
/// The pipeline is the one `IMAPClient` builds for a real connection, minus TLS and the socket: NIOIMAP's
/// `IMAPClientHandler` (which encodes commands, parses responses, and enforces the order of an exchange) followed
/// by the command's own handler. An `EmbeddedChannel` stands in for the network. It runs everything synchronously
/// on the calling thread, so a test reads top to bottom as the conversation it describes.
private final class Exchange {
    /// How the command ended; `nil` while it is still waiting for the server.
    var outcome: Result<[IMAP.Capability], IMAPError>? { recorder.outcome }

    /// Starts the exchange by writing the `AUTHENTICATE` command, as `IMAPClient.execute` does.
    init(_ authentication: Authentication, tag: String = "A01") throws {
        let command: AuthenticateCommand = AuthenticateCommand(authentication)
        promise = channel.eventLoop.makePromise(of: [IMAP.Capability].self)
        // Record the outcome when it arrives. `wait()` isn't an option: on an embedded event loop, waiting for a
        // command the server hasn't finished would block the test forever. The callback keeps the recorder alive
        // and not `self`, because `deinit` below can be what triggers it.
        promise.futureResult.assumeIsolated().whenComplete { [recorder] result in
            recorder.outcome = result.mapError { IMAPError($0) }
        }
        try channel.pipeline.syncOperations.addHandler(IMAPClientHandler())
        try channel.pipeline.syncOperations.addHandler(command.handler(tag: tag, promise: promise))
        try send(command.tagged(tag))
    }

    deinit {
        // NIO treats a promise that is dropped without a result as a bug and traps. A test that fails partway
        // through would otherwise take the whole test run down with it. Does nothing if the command has ended.
        promise.fail(IMAPError.notConnected)
    }

    /// The capabilities the command produced, if it succeeded.
    var capabilities: [IMAP.Capability]? {
        guard case .success(let capabilities) = outcome else { return nil }
        return capabilities
    }

    /// The error the command failed with, if it failed.
    var error: IMAPError? {
        guard case .failure(let error) = outcome else { return nil }
        return error
    }

    /// The details of the rejection, if the command failed with `IMAPError.authenticationFailed`.
    ///
    /// `IMAPError` compares by description, which leaves out part of the failure, so tests read the values here
    /// and check them one by one.
    var rejection: Rejection? {
        guard case .authenticationFailed(let text, let failure) = error else { return nil }
        return Rejection(text: text, failure: failure)
    }

    /// Delivers one line from the server; the line ending is added here.
    func receive(_ line: String) throws {
        try channel.writeInbound(ByteBuffer(string: "\(line)\r\n"))
    }

    /// Writes a command to the connection.
    func send(_ command: TaggedCommand) throws {
        try channel.writeOutbound(IMAPClientHandler.Message.part(.tagged(command)))
    }

    /// Everything the client has put on the wire since the last call, line endings included.
    func sent() throws -> String {
        var sent: String = ""
        while let buffer: ByteBuffer = try channel.readOutbound(as: ByteBuffer.self) {
            sent += String(buffer: buffer)
        }
        return sent
    }

    /// Skips over what the client has sent so far, for tests that only care about what comes next.
    func discardSent() throws {
        _ = try sent()
    }

    private final class Recorder {
        var outcome: Result<[IMAP.Capability], IMAPError>?
    }

    private let channel: EmbeddedChannel = EmbeddedChannel()
    private let promise: EventLoopPromise<[IMAP.Capability]>
    private let recorder: Recorder = Recorder()
}

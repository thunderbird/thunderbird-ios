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
    @Test func name() {
        #expect(AuthenticateCommand(.xoauth2("user@example.com", token: "t0k3n")).name == "authenticate \"user@example.com\"")
    }

    // The name ends up in logs and in `IMAPError.commandFailed`
    @Test func nameOmitsCredential() {
        #expect(!AuthenticateCommand(.oauthbearer("user@example.com", token: "t0k3n")).name.contains("t0k3n"))
        #expect(!AuthenticateCommand(.plain("user@example.com", password: "pa55w0rd")).name.contains("pa55w0rd"))
        #expect(!AuthenticateCommand(.xoauth2("user@example.com", token: "t0k3n")).name.contains("t0k3n"))
    }
}

// Each test below scripts the server's half of an `AUTHENTICATE` exchange and checks the client's half, byte for
// byte. `C:` and `S:` in the comments mark what the client and the server send.
//
// Nothing here touches the network. `Exchange` (at the bottom of this file) runs the same two handlers that
// `IMAPClient` puts on a real connection, so the bytes checked here are the bytes a server would see.
struct AuthenticateHandlerTests {

    // MARK: Rejected credential

    // The exchange from Google's XOAUTH2 protocol document, using its example user, token and error challenge:
    // https://developers.google.com/workspace/gmail/imap/xoauth2-protocol
    //
    // This is the scenario that used to hang: the server sends a challenge and waits, and nothing answered it.
    @Test func xoauth2RejectedToken() throws {
        let exchange: Exchange = try Exchange(.xoauth2("someuser@example.com", token: "ya29.vF9dft4qmTc2Nvb3RlckBhdHRhdmlzdGEuY29tCg"))

        // C: The credential goes out with the command, as the initial response (RFC 4959). The base64 is the
        //    document's own example, so this also pins our encoding to Google's.
        #expect(
            try exchange.sent()
                == "A01 AUTHENTICATE XOAUTH2 dXNlcj1zb21ldXNlckBleGFtcGxlLmNvbQFhdXRoPUJlYXJlciB5YTI5LnZGOWRmdDRxbVRjMk52YjNSbGNrQmhkSFJoZG1semRHRXVZMjl0Q2cBAQ==\r\n")

        // S: The token is rejected. Decoded: {"status":"401","schemes":"bearer mac","scope":"https://mail.google.com/"}
        try exchange.receive("+ eyJzdGF0dXMiOiI0MDEiLCJzY2hlbWVzIjoiYmVhcmVyIG1hYyIsInNjb3BlIjoiaHR0cHM6Ly9tYWlsLmdvb2dsZS5jb20vIn0K")

        // C: "The client sends an empty response ("\r\n") to the challenge containing the error message."
        #expect(try exchange.sent() == "\r\n")

        // The challenge explains the failure but doesn't end the command; only the tagged response does
        #expect(exchange.outcome == nil)

        // S: Now that it has its answer, the server ends the command
        try exchange.receive("A01 NO SASL authentication failed")

        let rejection: Rejection = try #require(exchange.rejection)
        #expect(rejection.text == "SASL authentication failed")
        #expect(rejection.failure?.status == "401")
        #expect(rejection.failure?.schemes == "bearer mac")
        #expect(rejection.failure?.scope == "https://mail.google.com/")
        #expect(rejection.failure?.openIDConfiguration == nil)
    }

    // The failed exchange from RFC 7628, section 4.3, using its error challenge:
    // https://www.rfc-editor.org/rfc/rfc7628#section-4.3
    @Test func oauthbearerRejectedToken() throws {
        let exchange: Exchange = try Exchange(.oauthbearer("user@example.com", token: "t0k3n"))

        // C: The RFC's example also sends the optional `host` and `port` pairs, which this client leaves out, so
        //    the initial response is built here and not copied from the RFC
        let initialResponse: String = Data("n,a=user@example.com,\u{01}auth=Bearer t0k3n\u{01}\u{01}".utf8).base64EncodedString()
        #expect(try exchange.sent() == "A01 AUTHENTICATE OAUTHBEARER \(initialResponse)\r\n")

        // S: Decoded: {"status":"invalid_token","scope":"example_scope",
        //              "openid-configuration":"https://example.com/.well-known/openid-configuration"}
        try exchange.receive(
            "+ eyJzdGF0dXMiOiJpbnZhbGlkX3Rva2VuIiwic2NvcGUiOiJleGFtcGxlX3Njb3BlIiwib3BlbmlkLWNvbmZpZ3VyYXRpb24iOiJodHRwczovL2V4YW1wbGUuY29tLy53ZWxsLWtub3duL29wZW5pZC1jb25maWd1cmF0aW9uIn0=")

        // C: "The client responds with the required dummy response; "AQ==" is the base64 encoding of the ASCII
        //    value 0x01." Unlike XOAUTH2, an empty line is not a valid answer here.
        #expect(try exchange.sent() == "AQ==\r\n")
        #expect(exchange.outcome == nil)

        // S:
        try exchange.receive("A01 NO SASL authentication failed")

        let rejection: Rejection = try #require(exchange.rejection)
        #expect(rejection.text == "SASL authentication failed")
        #expect(rejection.failure?.status == "invalid_token")
        #expect(rejection.failure?.scope == "example_scope")
        #expect(rejection.failure?.openIDConfiguration == "https://example.com/.well-known/openid-configuration")
        #expect(rejection.failure?.schemes == nil)
    }

    // A server may skip the challenge and go straight to NO. RFC 5530 gives it response codes to say why.
    @Test func rejectedWithoutChallenge() throws {
        let exchange: Exchange = try Exchange(.xoauth2("user@example.com", token: "t0k3n"))
        try exchange.discardSent()

        try exchange.receive("A01 NO [AUTHENTICATIONFAILED] Invalid credentials (Failure)")

        let rejection: Rejection = try #require(exchange.rejection)
        #expect(rejection.text == "Invalid credentials (Failure)")
        #expect(rejection.failure == nil)
        #expect(try exchange.sent().isEmpty)  // No challenge, so nothing to answer
    }

    // PLAIN has no challenge step at all (RFC 4616); a wrong password is a bare NO
    @Test func plainRejectedPassword() throws {
        let exchange: Exchange = try Exchange(.plain("user@example.com", password: "pa55w0rd"))
        try exchange.discardSent()

        try exchange.receive("A01 NO [AUTHENTICATIONFAILED] Authentication failed")

        let rejection: Rejection = try #require(exchange.rejection)
        #expect(rejection.text == "Authentication failed")
        #expect(rejection.failure == nil)
    }

    // MARK: Challenges that aren't an OAuth error result

    // Whatever the challenge says, the server is waiting, so it gets its answer. Only the detail is lost.
    @Test func unrecognizedChallengeIsStillAnswered() throws {
        let exchange: Exchange = try Exchange(.xoauth2("user@example.com", token: "t0k3n"))
        try exchange.discardSent()

        try exchange.receive("+ bm90IGpzb24=")  // "not json"
        #expect(try exchange.sent() == "\r\n")

        try exchange.receive("A01 NO SASL authentication failed")

        let rejection: Rejection = try #require(exchange.rejection)
        #expect(rejection.text == "SASL authentication failed")
        #expect(rejection.failure == nil)
    }

    // A challenge with no data at all, which is how a server prompts for a response it hasn't been given
    // (RFC 4959, section 3). Note the space after the "+": it is part of the syntax.
    @Test func emptyChallengeIsStillAnswered() throws {
        let exchange: Exchange = try Exchange(.oauthbearer("user@example.com", token: "t0k3n"))
        try exchange.discardSent()

        try exchange.receive("+ ")
        #expect(try exchange.sent() == "AQ==\r\n")

        try exchange.receive("A01 NO SASL authentication failed")
        #expect(exchange.rejection?.failure == nil)
    }

    // Each challenge gets exactly one answer, and a later challenge that carries no reason doesn't erase the
    // reason an earlier one gave
    @Test func everyChallengeIsAnsweredOnce() throws {
        let exchange: Exchange = try Exchange(.xoauth2("user@example.com", token: "t0k3n"))
        try exchange.discardSent()

        try exchange.receive("+ eyJzdGF0dXMiOiI0MDEiLCJzY2hlbWVzIjoiYmVhcmVyIG1hYyIsInNjb3BlIjoiaHR0cHM6Ly9tYWlsLmdvb2dsZS5jb20vIn0K")
        #expect(try exchange.sent() == "\r\n")

        try exchange.receive("+ ")
        #expect(try exchange.sent() == "\r\n")

        try exchange.receive("A01 NO SASL authentication failed")
        #expect(exchange.rejection?.failure?.status == "401")
    }

    // MARK: Accepted credential

    // The happy path must be untouched: no challenge, nothing extra written, capabilities collected
    @Test func acceptedToken() throws {
        let exchange: Exchange = try Exchange(.xoauth2("user@example.com", token: "t0k3n"))
        try exchange.discardSent()

        try exchange.receive("* CAPABILITY IMAP4rev1 IDLE NAMESPACE")
        #expect(exchange.outcome == nil)  // Untagged data doesn't end the command

        try exchange.receive("A01 OK Success")

        let capabilities: [IMAP.Capability] = try #require(exchange.capabilities)
        #expect(capabilities.contains(.idle))
        #expect(capabilities.count == 3)
        #expect(try exchange.sent().isEmpty)
    }

    // Not every server announces capabilities on sign-in
    @Test func acceptedTokenWithoutCapabilities() throws {
        let exchange: Exchange = try Exchange(.oauthbearer("user@example.com", token: "t0k3n"))

        try exchange.receive("A01 OK Success")

        #expect(try #require(exchange.capabilities).isEmpty)
    }

    // MARK: Protocol errors

    // BAD means the command itself was at fault ("command unknown or arguments invalid, authentication exchange
    // cancelled", RFC 3501, section 6.2.2). It says nothing about the credential, so it must not be reported as
    // a rejection: that would send the account layer off to refresh a token that may be perfectly good.
    @Test func badIsNotARejection() throws {
        let exchange: Exchange = try Exchange(.xoauth2("user@example.com", token: "t0k3n"))

        try exchange.receive("A01 BAD Invalid SASL argument")

        #expect(exchange.rejection == nil)
        #expect(exchange.error == .commandFailed("Invalid SASL argument"))
    }

    // MARK: Connection state

    // An unanswered challenge leaves NIOIMAP's state machine unable to take another command: it traps on one
    // written before the server's tagged response, and refuses every one written after it (`InvalidClientState`).
    // So the answer isn't only about speed: it is what returns the connection to a state where the next command
    // can be written at all.
    @Test func connectionIsUsableAfterRejection() throws {
        let exchange: Exchange = try Exchange(.xoauth2("user@example.com", token: "t0k3n"))
        try exchange.receive("+ eyJzdGF0dXMiOiI0MDEiLCJzY2hlbWVzIjoiYmVhcmVyIG1hYyIsInNjb3BlIjoiaHR0cHM6Ly9tYWlsLmdvb2dsZS5jb20vIn0K")
        try exchange.receive("A01 NO SASL authentication failed")
        try exchange.discardSent()

        try exchange.send(CapabilityCommand().tagged("A02"))

        #expect(try exchange.sent() == "A02 CAPABILITY\r\n")
    }
}

// The OAuth cases of `RealImapConnectionTest.kt` in thunderbird-android
// (mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap), with its user name, token and server lines.
// `//Android:` names the test each case comes from.
//
// Android runs every case against a mock server over a socket and starts from the greeting. These start at the
// `AUTHENTICATE` command, which is where this client's OAuth-specific behavior begins, and use tag `A01` where
// Android's connection uses `2`.
//
// Android cases with nothing here to test against are listed at the end of the suite.
struct AuthenticateHandlerAndroidTests {
    // USERNAME and XOAUTH_TOKEN in the Android test
    private static let user: String = "user"
    private static let token: String = "token"

    // XOAUTH_STRING and OAUTHBEARER_STRING in the Android test: the initial responses, base64-encoded
    private static let xoauth2String: String = Data("user=user\u{01}auth=Bearer token\u{01}\u{01}".utf8).base64EncodedString()
    private static let oauthBearerString: String = Data("n,a=user,\u{01}auth=Bearer token\u{01}\u{01}".utf8).base64EncodedString()

    // MARK: Accepted token

    //Expect: Send `AUTHENTICATE OAUTHBEARER` with the initial response on the same line.
    //Case: When signing in with OAUTHBEARER.
    //Android: `open() AUTH OAUTHBEARER`
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
    //Android: `open() AUTH OAUTHBEARER`
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
    //Android: `open() AUTH XOAUTH2 with SASL-IR`
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
    //Android: `open() AUTH XOAUTH2 with SASL-IR`
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
    //Android: `open() AUTH XOAUTH2 with untagged CAPABILITY response after authentication`
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
    //Android: `open() AUTH XOAUTH2 parses capabilities`
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
    //  Android's test payloads; the last two are the unreadable challenges of its retry test.
    //Android: `open() AUTH XOAUTH2 throws exception on 401 response`, `…invalidates and retries new token on 400
    //  response`, `…on invalid JSON response`, `…on missing status JSON response`, `…with old token throws exception
    //  if retry fails`. Every one of them has the client send an empty line after the challenge.
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
    //Android: `open() AUTH XOAUTH2 throws exception on 401 response`, which expects `messageFromServer` to be
    //  `SASL authentication failed`.
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
    //Case: When the challenge is Android's `STATUS_401_RESPONSE` or `STATUS_400_RESPONSE`.
    //Android: `open() AUTH XOAUTH2 throws exception on 401 response` and `…invalidates and retries new token on 400
    //  response`. Android acts on the status itself (400 means retry); this client hands it to the caller.
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
    //Android: `…on invalid JSON response`, `…on missing status JSON response` and `…with old token throws exception
    //  if retry fails`.
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
    // The base64 half of Android's `OAuthBearerTest.kt`; the text half is in `AuthenticationTests`. The expected
    // strings are Android's, so a match here means both clients put the same bytes on the wire.

    //Expect: Send the same base64 as Android.
    //Case: When an OAUTHBEARER user name needs no encoding, contains `=`, or contains `,`.
    //Android: `username that does not need encoding`, `username contains equal sign that needs to be encoded` and
    //  `username contains comma that needs to be encoded`
    @Test(arguments: [
        ("user@domain.example", "bixhPXVzZXJAZG9tYWluLmV4YW1wbGUsAWF1dGg9QmVhcmVyIHRva2VuAQE="),
        ("user=name@domain.example", "bixhPXVzZXI9M0RuYW1lQGRvbWFpbi5leGFtcGxlLAFhdXRoPUJlYXJlciB0b2tlbgEB"),
        ("user,name", "bixhPXVzZXI9MkNuYW1lLAFhdXRoPUJlYXJlciB0b2tlbgEB")
    ])
    func authenticate_sendsAndroidInitialResponse_whenMechanismIsOAuthBearer(_ user: String, _ expected: String) throws {
        // Arrange
        let input: Authentication = .oauthbearer(user, token: "token")

        // Act
        let exchange: Exchange = try Exchange(input)
        let actual = try exchange.sent()

        // Assert
        #expect(actual == "A01 AUTHENTICATE OAUTHBEARER \(expected)\r\n")
    }

    // Android OAuth cases that are not here, because this client has nothing for them to test:
    //
    // - `open() AUTH OAUTHBEARER when AUTH=XOAUTH2 and AUTH=OAUTHBEARER capabilities are present`: Android picks
    //   OAUTHBEARER when a server offers both. Here the caller picks the mechanism, and the account layer always
    //   picks XOAUTH2.
    // - `open() AUTH OAUTHBEARER with SASL-IR capability missing`: Android refuses to sign in without SASL-IR.
    //   `IMAPClient.authenticate` doesn't check it for the OAuth mechanisms.
    // - `…invalidates and retries new token on 400 response`, `…on invalid JSON response`, `…on missing status JSON
    //   response` and `…with old token throws exception if retry fails`: Android asks its token provider for a new
    //   token and tries once more. `IMAPClient` has no token provider; it reports the rejection and stops. The
    //   server's half of those exchanges, up to the first NO, is covered above.
    // - After a sign-in that announced no capabilities, Android sends CAPABILITY. `IMAPClient` doesn't.
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

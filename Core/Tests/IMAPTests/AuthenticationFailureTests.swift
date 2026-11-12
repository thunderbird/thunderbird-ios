// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import IMAP
import NIOCore
import Testing

// `AuthenticationFailure` decodes the JSON a server sends in a challenge when it rejects an OAuth token. NIOIMAP
// has base64-decoded the challenge before it gets here, so these tests start from the JSON text.
struct AuthenticationFailureTests {

    // The error result from Google's XOAUTH2 protocol document, including the trailing newline its example
    // carries: https://developers.google.com/workspace/gmail/imap/xoauth2-protocol
    @Test func xoauth2() throws {
        let failure: AuthenticationFailure = try #require(AuthenticationFailure(#"{"status":"401","schemes":"bearer mac","scope":"https://mail.google.com/"}"# + "\n"))
        #expect(failure.status == "401")
        #expect(failure.schemes == "bearer mac")
        #expect(failure.scope == "https://mail.google.com/")
        #expect(failure.openIDConfiguration == nil)  // Not part of XOAUTH2
    }

    // The error result from RFC 7628, section 4.3: https://www.rfc-editor.org/rfc/rfc7628#section-4.3
    @Test func oauthbearer() throws {
        let failure: AuthenticationFailure = try #require(
            AuthenticationFailure(#"{"status":"invalid_token","scope":"example_scope","openid-configuration":"https://example.com/.well-known/openid-configuration"}"#))
        #expect(failure.status == "invalid_token")
        #expect(failure.scope == "example_scope")
        #expect(failure.openIDConfiguration == "https://example.com/.well-known/openid-configuration")
        #expect(failure.schemes == nil)  // Not part of OAUTHBEARER
    }

    // `status` is the only required value (RFC 7628, section 3.2.2); a missing scope "implies that unscoped
    // tokens are required"
    @Test func statusOnly() throws {
        let failure: AuthenticationFailure = try #require(AuthenticationFailure(#"{"status":"invalid_token"}"#))
        #expect(failure.status == "invalid_token")
        #expect(failure.scope == nil)
        #expect(failure.schemes == nil)
        #expect(failure.openIDConfiguration == nil)
    }

    // Servers may add values of their own; they must not make the known ones unreadable
    @Test func unknownValuesAreIgnored() throws {
        let failure: AuthenticationFailure = try #require(AuthenticationFailure(#"{"status":"400","schemes":"Bearer","scope":"scope","trace":{"id":7}}"#))
        #expect(failure.status == "400")
        #expect(failure.schemes == "Bearer")
        #expect(failure.scope == "scope")
    }

    // A challenge is only an error result by convention. Anything else decodes to nothing and is not an error.
    @Test(arguments: [
        "",  // Zero-length challenge
        "not json",
        "[]",  // JSON, but not an object
        #"{"scope":"example_scope"}"#,  // No status
        #"{"status":401}"#,  // Status must be a string
        #"{"status":"401""#  // Truncated
    ])
    func unrecognizedChallenge(_ challenge: String) {
        #expect(AuthenticationFailure(challenge) == nil)
    }

    // MARK: Shared challenge payloads
    // Four payloads shared with another Thunderbird client. Each test has a `//Source:` line linking to the payload
    // it uses. The source client feeds them to a parser that answers one question: is it worth retrying with a new
    // token? (Yes for status 400, a missing status and unreadable JSON; no for anything else.) This client has no
    // such retry, so the payloads are checked for what it does do with them, which is decode the status.

    //Expect: Decode the status as `400`.
    //Case: When the challenge is the shared `STATUS_400_RESPONSE` payload.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/testing/src/main/java/com/fsck/k9/mail/testing/XOAuth2ChallengeParserTestData.java#L7
    @Test func init_decodesStatus_whenChallengeHasStatus400() {
        // Arrange
        let input = XOAuth2ChallengeTestData.status400Response

        // Act
        let actual = AuthenticationFailure(input)?.status

        // Assert
        #expect(actual == "400")
    }

    //Expect: Decode the status as `401`.
    //Case: When the challenge is the shared `STATUS_401_RESPONSE` payload.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/testing/src/main/java/com/fsck/k9/mail/testing/XOAuth2ChallengeParserTestData.java#L9
    @Test func init_decodesStatus_whenChallengeHasStatus401() {
        // Arrange
        let input = XOAuth2ChallengeTestData.status401Response

        // Act
        let actual = AuthenticationFailure(input)?.status

        // Assert
        #expect(actual == "401")
    }

    //Expect: Return `nil`.
    //Case: When the challenge is the shared `MISSING_STATUS_RESPONSE` payload, valid JSON without a `status`.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/testing/src/main/java/com/fsck/k9/mail/testing/XOAuth2ChallengeParserTestData.java#L11
    @Test func init_returnsNil_whenChallengeHasNoStatus() {
        // Arrange
        let input = XOAuth2ChallengeTestData.missingStatusResponse

        // Act
        let actual = AuthenticationFailure(input)

        // Assert
        #expect(actual == nil)
    }

    //Expect: Return `nil`.
    //Case: When the challenge is the shared `INVALID_RESPONSE` payload, JSON that is cut off before its closing
    //  brace.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/testing/src/main/java/com/fsck/k9/mail/testing/XOAuth2ChallengeParserTestData.java#L13
    @Test func init_returnsNil_whenChallengeIsInvalidJSON() {
        // Arrange
        let input = XOAuth2ChallengeTestData.invalidResponse

        // Act
        let actual = AuthenticationFailure(input)

        // Assert
        #expect(actual == nil)
    }

    // MARK: CustomStringConvertible
    @Test func description() {
        #expect(AuthenticationFailure(#"{"status":"401","schemes":"bearer","scope":"https://mail.google.com/"}"#)?.description == "401, scope: https://mail.google.com/")
        #expect(AuthenticationFailure(#"{"status":"invalid_token"}"#)?.description == "invalid_token")
        #expect(AuthenticationFailure(#"{"status":"invalid_token","scope":""}"#)?.description == "invalid_token")
    }
}

private extension AuthenticationFailure {
    init?(_ json: String) {
        self.init(ByteBuffer(string: json))
    }
}

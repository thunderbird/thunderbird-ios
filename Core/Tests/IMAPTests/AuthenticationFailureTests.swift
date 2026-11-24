// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import IMAP
import NIOCore
import Testing

// `AuthenticationFailure` decodes the JSON a server sends in a challenge when it rejects an OAuth token. NIOIMAP
// has base64-decoded the challenge before it gets here, so these tests start from the JSON text.
struct AuthenticationFailureTests {

    // MARK: Error results

    //Expect: Decode the status, schemes and scope, and leave the OpenID configuration empty.
    //Case: When the challenge is the error result from Google's XOAUTH2 protocol document, including the trailing
    //  newline its example carries: https://developers.google.com/workspace/gmail/imap/xoauth2-protocol
    @Test func init_decodesStatusSchemesAndScope_whenChallengeIsXOAuth2ErrorResult() {
        // Arrange
        let input = #"{"status":"401","schemes":"bearer mac","scope":"https://mail.google.com/"}"# + "\n"
        let expected = Values(status: "401", scope: "https://mail.google.com/", schemes: "bearer mac", openIDConfiguration: nil)

        // Act
        let actual = AuthenticationFailure(input)?.values

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the status, scope and OpenID configuration, and leave the schemes empty.
    //Case: When the challenge is the error result from RFC 7628, section 4.3:
    //  https://www.rfc-editor.org/rfc/rfc7628#section-4.3
    @Test func init_decodesStatusScopeAndOpenIDConfiguration_whenChallengeIsOAuthBearerErrorResult() {
        // Arrange
        let input = #"{"status":"invalid_token","scope":"example_scope","openid-configuration":"https://example.com/.well-known/openid-configuration"}"#
        let expected = Values(status: "invalid_token", scope: "example_scope", schemes: nil, openIDConfiguration: "https://example.com/.well-known/openid-configuration")

        // Act
        let actual = AuthenticationFailure(input)?.values

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the status and leave every other value empty.
    //Case: When the challenge has only a `status`, the one required value (RFC 7628, section 3.2.2). A missing
    //  scope "implies that unscoped tokens are required".
    @Test func init_decodesStatusAlone_whenChallengeHasOnlyStatus() {
        // Arrange
        let input = #"{"status":"invalid_token"}"#
        let expected = Values(status: "invalid_token", scope: nil, schemes: nil, openIDConfiguration: nil)

        // Act
        let actual = AuthenticationFailure(input)?.values

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the known values.
    //Case: When the challenge also has a value this client doesn't know. Servers may add values of their own.
    @Test func init_decodesKnownValues_whenChallengeHasUnknownValue() {
        // Arrange
        let input = #"{"status":"400","schemes":"Bearer","scope":"scope","trace":{"id":7}}"#
        let expected = Values(status: "400", scope: "scope", schemes: "Bearer", openIDConfiguration: nil)

        // Act
        let actual = AuthenticationFailure(input)?.values

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return `nil`.
    //Case: When the challenge isn't an error result. A challenge is only one by convention, so anything else
    //  decodes to nothing and is not an error.
    @Test(arguments: [
        "",  // Zero-length challenge
        "not json",
        "[]",  // JSON, but not an object
        #"{"scope":"example_scope"}"#,  // No status
        #"{"status":401}"#,  // Status must be a string
        #"{"status":"401""#  // Truncated
    ])
    func init_returnsNil_whenChallengeIsNotAnErrorResult(_ input: String) {
        // Act
        let actual = AuthenticationFailure(input)

        // Assert
        #expect(actual == nil)
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

    //Expect: Describe the status, followed by the scope when there is one.
    //Case: When the error result has a scope, has none, or has an empty one.
    @Test(arguments: [
        (#"{"status":"401","schemes":"bearer","scope":"https://mail.google.com/"}"#, "401, scope: https://mail.google.com/"),
        (#"{"status":"invalid_token"}"#, "invalid_token"),
        (#"{"status":"invalid_token","scope":""}"#, "invalid_token")
    ])
    func description_showsStatusAndScope_whenErrorResultIsDescribed(_ input: String, _ expected: String) {
        // Act
        let actual = AuthenticationFailure(input)?.description

        // Assert
        #expect(actual == expected)
    }
}

// The values of an error result, so that a test can compare all of them in one expectation
private struct Values: Equatable {
    let status: String
    let scope: String?
    let schemes: String?
    let openIDConfiguration: String?
}

private extension AuthenticationFailure {
    init?(_ json: String) {
        self.init(ByteBuffer(string: json))
    }

    var values: Values {
        Values(status: status, scope: scope, schemes: schemes, openIDConfiguration: openIDConfiguration)
    }
}

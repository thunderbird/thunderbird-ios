// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Autoconfiguration
import Foundation
import Testing

// Tests for behavior that is known to be wrong today. Each one states what should happen and is expected to fail
// until its issue is fixed.
//
// `withKnownIssue` records the failure as a known issue, so the suite stays green. When a fix lands the expectation
// starts to pass, the test then fails with "known issue was not encountered", and the `withKnownIssue` wrapper
// has to be removed. The `.bug` trait links each test to its issue.
struct KnownIssueTests {
    //Expect: Keep the refresh token the server sent.
    //Case: When a refresh response includes a new refresh token (RFC 6749, section 6).
    //Example: `RefreshTokenResponse` has no property for it yet, so this looks for one by name.
    @Test(.bug("https://github.com/thunderbird/thunderbird-ios/issues/659", "OAuth: a new refresh token returned by a refresh is discarded"))
    func refreshTokenResponseInit_keepsRefreshToken_whenResponseIncludesOne() throws {
        // Arrange
        let input = Data(#"{"access_token":"ACCESS","expires_in":3600,"refresh_token":"NEW"}"#.utf8)

        // Act
        let response = try JSONDecoder().decode(RefreshTokenResponse.self, from: input)
        let actual = Mirror(reflecting: response).children.contains { "\($0.value)".contains("NEW") }

        // Assert
        withKnownIssue("Tracked in #659") {
            #expect(actual == true)
        }
    }

    //Expect: Decode the response.
    //Case: When a token response leaves out `refresh_token` (OPTIONAL) or `expires_in` (RECOMMENDED); RFC 6749,
    //  section 5.1.
    @Test(
        .bug("https://github.com/thunderbird/thunderbird-ios/issues/660", "OAuth: token endpoint errors aren't decoded, and optional response fields are treated as required"),
        arguments: [
            #"{"access_token":"ACCESS","token_type":"Bearer","expires_in":3600}"#,
            #"{"access_token":"ACCESS","token_type":"Bearer","refresh_token":"REFRESH"}"#
        ])
    func tokenResponseInit_decodes_whenOptionalFieldIsMissing(_ json: String) {
        // Arrange
        let input = Data(json.utf8)

        withKnownIssue("Tracked in #660") {
            // Act & Assert
            #expect(throws: Never.self) {
                try JSONDecoder().decode(TokenResponse.self, from: input)
            }
        }
    }

    //Expect: Refuse the response.
    //Case: When the token type isn't `Bearer` (RFC 6749, section 7.1).
    @Test(.bug("https://github.com/thunderbird/thunderbird-ios/issues/660", "OAuth: token endpoint errors aren't decoded, and optional response fields are treated as required"))
    func tokenResponseInit_throws_whenTokenTypeIsNotBearer() {
        // Arrange
        let input = Data(#"{"access_token":"ACCESS","token_type":"mac","expires_in":3600,"refresh_token":"REFRESH"}"#.utf8)

        withKnownIssue("Tracked in #660") {
            // Act & Assert
            #expect(throws: (any Error).self) {
                try JSONDecoder().decode(TokenResponse.self, from: input)
            }
        }
    }

    //Expect: Send a `state` parameter.
    //Case: When building the authorization URL for a sign-in (RFC 8252, section 8.9).
    @Test(.bug("https://github.com/thunderbird/thunderbird-ios/issues/663", "OAuth: the sign-in callback isn't validated (no state, redirect URI not compared, error ignored)"))
    func authURL_includesState_whenBuildingAuthorizationRequest() throws {
        // Arrange
        let configuration = try OAuth2.Configuration(
            authURI: "https://example.com/auth",
            tokenURI: "https://example.com/token",
            redirectURI: "com.example:/oauth2redirect",
            responseType: "code",
            scope: ["mail"],
            clientID: "client"
        )

        // Act
        let url = configuration.authURL(pkce: OAuth2.PKCE())
        let actual = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.contains { $0.name == "state" && !($0.value ?? "").isEmpty }

        // Assert
        withKnownIssue("Tracked in #663") {
            #expect(actual == true)
        }
    }
}

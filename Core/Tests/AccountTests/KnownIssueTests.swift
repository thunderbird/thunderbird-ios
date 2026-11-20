// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Account
import Foundation
import Testing

// Tests for behavior that is known to be wrong today. Each one states what should happen and is expected to fail
// until its issue is fixed.
//
// `withKnownIssue` records the failure as a known issue, so the suite stays green. When a fix lands the expectation
// starts to pass, the test then fails with "known issue was not encountered", and the `withKnownIssue` wrapper
// has to be removed. The `.bug` trait links each test to its issue.
struct KnownIssueTests {
    //Expect: Create the SMTP server without throwing.
    //Case: When the account signs in with OAuth.
    @Test(.bug("https://github.com/thunderbird/thunderbird-ios/issues/655", "SMTP: OAuth accounts are refused, so an account signed in with OAuth can't send mail"))
    func smtpServerInit_doesNotThrow_whenAccountUsesOAuth() {
        // Arrange
        let server = Server(.smtp, connectionSecurity: .startTLS, authenticationType: .oauth2, username: "user@example.com", hostname: "smtp.example.com")
        let authorization: Authorization = .oauth(user: "user@example.com", token: .bearer("ACCESS", .distantFuture), refresh: .refresh("REFRESH"))

        withKnownIssue("Tracked in #655") {
            // Act & Assert
            #expect(throws: Never.self) {
                try SMTP.Server(server, authorization: authorization)
            }
        }
    }

    //Expect: Leave the access token and refresh token out of the description.
    //Case: When an OAuth authorization is described, as happens when it is printed, logged or interpolated.
    @Test(.bug("https://github.com/thunderbird/thunderbird-ios/issues/666", "Account: Authorization's description returns the stored credential, including the refresh token"))
    func description_omitsStoredCredential_whenAuthorizationIsOAuth() {
        // Arrange
        let input: Authorization = .oauth(user: "user@example.com", token: .bearer("ACCESS", .distantFuture), refresh: .refresh("REFRESH"))

        // Act
        let actual = input.description.contains(input.password)

        // Assert
        withKnownIssue("Tracked in #666") {
            #expect(actual == false)
        }
    }

    //Expect: Leave the password out of the description.
    //Case: When a basic authorization is described.
    @Test(.bug("https://github.com/thunderbird/thunderbird-ios/issues/666", "Account: Authorization's description returns the stored credential, including the refresh token"))
    func description_omitsStoredCredential_whenAuthorizationIsBasic() {
        // Arrange
        let input: Authorization = .basic(user: "user@example.com", password: "hunter2")

        // Act
        let actual = input.description.contains(input.password)

        // Assert
        withKnownIssue("Tracked in #666") {
            #expect(actual == false)
        }
    }

    //Expect: Read the credential back as the same user and password.
    //Case: When the password contains a colon, which is also the separator of the stored form.
    @Test(.bug("https://github.com/thunderbird/thunderbird-ios/issues/667", "Account: a password containing \":\" is read back as an OAuth credential or as nothing"), arguments: ["a:b", "a:b:c"])
    func init_readsBackSamePassword_whenPasswordContainsColon(_ password: String) {
        // Arrange
        let expected: Authorization = .basic(user: "user@example.com", password: password)

        // Act
        let actual = Authorization(user: "user@example.com", password: expected.password)

        // Assert
        withKnownIssue("Tracked in #667") {
            #expect(actual == expected)
        }
    }
}

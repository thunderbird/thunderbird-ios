// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import IMAP
import NIOCore
import NIOIMAPCore
import Testing

struct AuthenticationTests {
    //Expect: Use the SASL mechanism that matches the kind of credential.
    //Case: When a credential is created for each mechanism.
    @Test(arguments: [
        (Authentication.oauthbearer("user@example.com", token: "t0k3n"), Authentication.Mechanism.oauthBearer),
        (Authentication.plain("user@example.com", password: "pa55w0rd"), Authentication.Mechanism.plain),
        (Authentication.xoauth2("user@example.com", token: "t0k3n"), Authentication.Mechanism.xoauth2)
    ])
    func mechanism_matchesCredential_whenAuthenticationIsCreated(_ input: Authentication, _ expected: Authentication.Mechanism) {
        // Act
        let actual = input.mechanism

        // Assert
        #expect(actual == expected)
    }

    //Expect: Use the mechanism's registered name, which is what follows `AUTHENTICATE` on the wire.
    //Case: When the mechanism is one of the two this client adds for OAuth.
    @Test(arguments: [
        (Authentication.Mechanism.oauthBearer, "OAUTHBEARER"),
        (Authentication.Mechanism.xoauth2, "XOAUTH2")
    ])
    func mechanism_hasRegisteredName_whenMechanismIsForOAuth(_ input: Authentication.Mechanism, _ expected: String) {
        // Act
        let actual = String(input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the user the credential was created with.
    //Case: When a credential is created for each mechanism.
    @Test(arguments: [
        Authentication.oauthbearer("user@example.com", token: "t0k3n"),
        Authentication.plain("user@example.com", password: "pa55w0rd"),
        Authentication.xoauth2("user@example.com", token: "t0k3n")
    ])
    func user_returnsUser_whenAuthenticationIsCreated(_ input: Authentication) {
        // Act
        let actual = input.user

        // Assert
        #expect(actual == "user@example.com")
    }

    //Expect: Build the initial response the mechanism defines. `\u{01}` is Control+A and `\u{00}` is NUL.
    //Case: When a credential is created for each mechanism.
    //  OAUTHBEARER (RFC 7628): a GS2 header, then Control+A-delimited key/value pairs, ended by two Control+A.
    //  PLAIN (RFC 4616): an empty authorization identity, then the NUL-delimited user and password.
    //  XOAUTH2: https://developers.google.com/workspace/gmail/imap/xoauth2-protocol
    @Test(arguments: [
        (Authentication.oauthbearer("user@example.com", token: "t0k3n"), "n,a=user@example.com,\u{01}auth=Bearer t0k3n\u{01}\u{01}"),
        (Authentication.plain("user@example.com", password: "pa55w0rd"), "\u{00}user@example.com\u{00}pa55w0rd"),
        (Authentication.xoauth2("user@example.com", token: "t0k3n"), "user=user@example.com\u{01}auth=Bearer t0k3n\u{01}\u{01}")
    ])
    func initialResponse_followsMechanismFormat_whenAuthenticationIsCreated(_ input: Authentication, _ expected: String) throws {
        // Act
        let actual = try input.initialResponse.string

        // Assert
        #expect(actual == expected)
    }

    //Expect: Encode the user and password as UTF-8.
    //Case: When they contain characters outside ASCII.
    @Test func initialResponse_encodesUTF8_whenUserAndPasswordAreNotASCII() throws {
        // Arrange
        let input: Authentication = .plain("üser@example.com", password: "pässw0rd")
        let expected = "\u{00}üser@example.com\u{00}pässw0rd"

        // Act
        let actual = try input.initialResponse.string

        // Assert
        #expect(actual == expected)
    }

    //Expect: Answer a server challenge with the bytes the mechanism requires, before NIOIMAP base64-encodes them.
    //  See `AuthenticateHandlerTests` for these on the wire.
    //Case: When a credential is created for each mechanism.
    //  OAUTHBEARER (RFC 7628, section 3.2.3): "a single %x01 (control A) character".
    //  XOAUTH2 (Google's XOAUTH2 protocol): "an empty response".
    //  PLAIN: RFC 4616 defines no challenge; an empty response carries no credential.
    @Test(arguments: [
        (Authentication.oauthbearer("user@example.com", token: "t0k3n"), [UInt8(0x01)]),
        (Authentication.xoauth2("user@example.com", token: "t0k3n"), [UInt8]()),
        (Authentication.plain("user@example.com", password: "pa55w0rd"), [UInt8]())
    ])
    func challengeResponse_isMechanismAnswer_whenAuthenticationIsCreated(_ input: Authentication, _ expected: [UInt8]) {
        // Act
        let actual = Array(input.challengeResponse.readableBytesView)

        // Assert
        #expect(actual == expected)
    }

    // MARK: OAUTHBEARER user names, shared cases
    // Cases shared with another Thunderbird client, using the same inputs. Each has a `//Source:` line linking to
    // the test it was taken from. The source checks each response twice, as text and as base64. The text is checked
    // here, where the response is built; the base64 is checked in `AuthenticateExchangeTests`, where it goes on the
    // wire.

    //Expect: Send the user name as it is.
    //Case: When an OAUTHBEARER user name contains neither `,` nor `=`.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/legacy/core/src/test/java/com/fsck/k9/sasl/OAuthBearerTest.kt#L10
    @Test func initialResponse_sendsUserUnchanged_whenOAuthBearerUserNeedsNoEncoding() throws {
        // Arrange
        let input: Authentication = .oauthbearer("user@domain.example", token: "token")
        let expected = "n,a=user@domain.example,\u{01}auth=Bearer token\u{01}\u{01}"

        // Act
        let actual = try input.initialResponse.string

        // Assert
        #expect(actual == expected)
    }

    //Expect: Send `=` as `=3D`.
    //Case: When an OAUTHBEARER user name contains an equal sign, which is legal in an email address.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/legacy/core/src/test/java/com/fsck/k9/sasl/OAuthBearerTest.kt#L22
    @Test func initialResponse_encodesEqualSign_whenOAuthBearerUserContainsEqualSign() throws {
        // Arrange
        let input: Authentication = .oauthbearer("user=name@domain.example", token: "token")
        let expected = "n,a=user=3Dname@domain.example,\u{01}auth=Bearer token\u{01}\u{01}"

        // Act
        let actual = try input.initialResponse.string

        // Assert
        #expect(actual == expected)
    }

    //Expect: Send `,` as `=2C`.
    //Case: When an OAUTHBEARER user name contains a comma, which would otherwise end the user name early.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/legacy/core/src/test/java/com/fsck/k9/sasl/OAuthBearerTest.kt#L34
    @Test func initialResponse_encodesComma_whenOAuthBearerUserContainsComma() throws {
        // Arrange
        let input: Authentication = .oauthbearer("user,name", token: "token")
        let expected = "n,a=user=2Cname,\u{01}auth=Bearer token\u{01}\u{01}"

        // Act
        let actual = try input.initialResponse.string

        // Assert
        #expect(actual == expected)
    }

    // MARK: Encoding, beyond the shared cases

    //Expect: Encode each character once.
    //Case: When an OAUTHBEARER user name contains both `,` and `=`.
    //Example: Replacing `,` and then `=` in two passes would escape the `=` of `=2C` again and send `=3D2C`.
    @Test func initialResponse_encodesEachCharacterOnce_whenOAuthBearerUserContainsCommaAndEqualSign() throws {
        // Arrange
        let input: Authentication = .oauthbearer("a,b=c", token: "token")
        let expected = "n,a=a=2Cb=3Dc,\u{01}auth=Bearer token\u{01}\u{01}"

        // Act
        let actual = try input.initialResponse.string

        // Assert
        #expect(actual == expected)
    }

    //Expect: Send the user name as it is.
    //Case: When an XOAUTH2 user name contains `,` and `=`. XOAUTH2 separates its fields with Control+A and defines no
    //  encoding, so the OAUTHBEARER rule must not be applied to it.
    @Test func initialResponse_sendsUserUnchanged_whenXOAuth2UserContainsCommaAndEqualSign() throws {
        // Arrange
        let input: Authentication = .xoauth2("a,b=c", token: "token")
        let expected = "user=a,b=c\u{01}auth=Bearer token\u{01}\u{01}"

        // Act
        let actual = try input.initialResponse.string

        // Assert
        #expect(actual == expected)
    }

    // MARK: CustomStringConvertible

    //Expect: Describe the mechanism and the user.
    //Case: When a credential is described, for each mechanism.
    @Test(arguments: [
        (Authentication.oauthbearer("user@example.com", token: "t0k3n"), "OAUTHBEARER \"user@example.com\""),
        (Authentication.plain("user@example.com", password: "pa55w0rd"), "PLAIN \"user@example.com\""),
        (Authentication.xoauth2("user@example.com", token: ""), "XOAUTH2 \"user@example.com\"")
    ])
    func description_showsMechanismAndUser_whenAuthenticationIsDescribed(_ input: Authentication, _ expected: String) {
        // Act
        let actual = input.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Leave the token or password out of the description.
    //Case: When a credential is described, for each mechanism. Descriptions end up in logs.
    @Test(arguments: [
        (Authentication.oauthbearer("user@example.com", token: "t0k3n"), "t0k3n"),
        (Authentication.plain("user@example.com", password: "pa55w0rd"), "pa55w0rd"),
        (Authentication.xoauth2("user@example.com", token: "t0k3n"), "t0k3n")
    ])
    func description_omitsCredential_whenAuthenticationIsDescribed(_ input: Authentication, _ secret: String) {
        // Act
        let actual = input.description.contains(secret)

        // Assert
        #expect(actual == false)
    }
}

private extension InitialResponse {
    var string: String { String(buffer: data) }
}

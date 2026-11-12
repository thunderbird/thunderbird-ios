// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import IMAP
import NIOCore
import NIOIMAPCore
import Testing

struct AuthenticationTests {
    @Test func mechanism() {
        #expect(Authentication.oauthbearer("user@example.com", token: "t0k3n").mechanism == .oauthBearer)
        #expect(Authentication.plain("user@example.com", password: "pa55w0rd").mechanism == .plain)
        #expect(Authentication.xoauth2("user@example.com", token: "t0k3n").mechanism == .xoauth2)
        #expect(String(Authentication.Mechanism.oauthBearer) == "OAUTHBEARER")
        #expect(String(Authentication.Mechanism.xoauth2) == "XOAUTH2")
    }

    @Test func user() {
        #expect(Authentication.oauthbearer("user@example.com", token: "t0k3n").user == "user@example.com")
        #expect(Authentication.plain("user@example.com", password: "pa55w0rd").user == "user@example.com")
        #expect(Authentication.xoauth2("user@example.com", token: "t0k3n").user == "user@example.com")
    }

    // RFC 7628: GS2 header, then ^A-delimited key/value pairs, terminated with ^A^A
    @Test func oauthbearerInitialResponse() throws {
        let authentication: Authentication = .oauthbearer("user@example.com", token: "t0k3n")
        #expect(try authentication.initialResponse.string == "n,a=user@example.com,\u{01}auth=Bearer t0k3n\u{01}\u{01}")
    }

    // RFC 4616: Empty authorization identity, then NUL-delimited user and password
    @Test func plainInitialResponse() throws {
        let authentication: Authentication = .plain("user@example.com", password: "pa55w0rd")
        #expect(try authentication.initialResponse.string == "\u{00}user@example.com\u{00}pa55w0rd")
    }

    // https://developers.google.com/workspace/gmail/imap/xoauth2-protocol
    @Test func xoauth2InitialResponse() throws {
        let authentication: Authentication = .xoauth2("user@example.com", token: "t0k3n")
        #expect(try authentication.initialResponse.string == "user=user@example.com\u{01}auth=Bearer t0k3n\u{01}\u{01}")
    }

    @Test func initialResponseEncodesUTF8() throws {
        let authentication: Authentication = .plain("üser@example.com", password: "pässw0rd")
        #expect(try authentication.initialResponse.string == "\u{00}üser@example.com\u{00}pässw0rd")
    }

    // What each mechanism sends to answer a server challenge, before NIOIMAP base64-encodes it. See
    // `AuthenticateHandlerTests` for these on the wire.
    @Test func challengeResponse() {
        // RFC 7628, section 3.2.3: "a single %x01 (control A) character"
        #expect(Array(Authentication.oauthbearer("user@example.com", token: "t0k3n").challengeResponse.readableBytesView) == [0x01])
        // Google's XOAUTH2 protocol: "an empty response"
        #expect(Authentication.xoauth2("user@example.com", token: "t0k3n").challengeResponse.readableBytes == 0)
        // RFC 4616 defines no challenge for PLAIN; an empty response carries no credential
        #expect(Authentication.plain("user@example.com", password: "pa55w0rd").challengeResponse.readableBytes == 0)
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
    @Test func description() {
        #expect(Authentication.oauthbearer("user@example.com", token: "t0k3n").description == "OAUTHBEARER \"user@example.com\"")
        #expect(Authentication.plain("user@example.com", password: "pa55w0rd").description == "PLAIN \"user@example.com\"")
        #expect(Authentication.xoauth2("user@example.com", token: "").description == "XOAUTH2 \"user@example.com\"")
    }

    // Credentials should never leak into logs via description
    @Test func descriptionOmitsCredential() {
        #expect(!Authentication.oauthbearer("user@example.com", token: "t0k3n").description.contains("t0k3n"))
        #expect(!Authentication.plain("user@example.com", password: "pa55w0rd").description.contains("pa55w0rd"))
        #expect(!Authentication.xoauth2("user@example.com", token: "t0k3n").description.contains("t0k3n"))
    }
}

private extension InitialResponse {
    var string: String { String(buffer: data) }
}

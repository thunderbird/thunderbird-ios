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

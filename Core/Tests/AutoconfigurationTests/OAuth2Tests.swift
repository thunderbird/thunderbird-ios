// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Autoconfiguration
import Foundation
import Testing

struct OAuth2Tests {
    @Test func pkceGeneratesRFC7636Verifier() {
        let pkce = OAuth2.PKCE()
        let allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")

        #expect(pkce.codeVerifier.count == 43)
        #expect(pkce.codeVerifier.unicodeScalars.allSatisfy { allowedCharacters.contains($0) })
    }

    @Test func pkceRFC7636TestVector() {
        let pkce = OAuth2.PKCE(codeVerifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")

        #expect(pkce.codeChallenge == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }

    @Test func authURLIncludesPKCEChallenge() throws {
        let request: OAuth2.Request = try OAuth2.Request(
            authURI: "https://example.com/authorize",
            tokenURI: "https://example.com/token",
            redirectURI: "com.example:/oauth2redirect",
            responseType: "code",
            scope: [
                "mail-w"
            ],
            clientID: "Cl13n+-ID"
        )
        let pkce = OAuth2.PKCE(codeVerifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
        let queryItems = URLComponents(
            url: request.authURL(hint: "user@example.com", pkce: pkce),
            resolvingAgainstBaseURL: false
        )?.queryItems

        #expect(queryItems?.first(where: { $0.name == "code_challenge" })?.value == pkce.codeChallenge)
        #expect(queryItems?.first(where: { $0.name == "code_challenge_method" })?.value == "S256")
        #expect(queryItems?.first(where: { $0.name == "login_hint" })?.value == "user@example.com")
    }

    @Test func matches() throws {
        let request: OAuth2.Request = try OAuth2.Request(
            authURI: "https://example.com/authorize",
            tokenURI: "https://example.com/token",
            redirectURI: "com.example:/oauth2redirect",
            responseType: "code",
            scope: [
                "mail-w"
            ],
            clientID: "Cl13n+-ID",
            hosts: [
                "example.com",
                "examplemail.com"
            ]
        )
        #expect(request.matches("google.com") == false)
        #expect(request.matches("mail.example.com") == true)
        #expect(request.matches("examplemail.com") == true)
        #expect(request.matches("mail.com") == false)
    }
    @Test func decoderInit() throws {
        let oauth2: [OAuth2] = try JSONDecoder().decode([OAuth2].self, from: data)
        #expect(
            oauth2[0].scope == [
                "mail-w"
            ])
        #expect(
            oauth2[1].scope == [
                "https://mail.google.com/",
                "https://www.googleapis.com/auth/contacts",
                "https://www.googleapis.com/auth/calendar",
                "https://www.googleapis.com/auth/carddav"
            ])
        #expect(
            oauth2[2].scope == [
                "mail-w"
            ])
    }
}

// swift-format-ignore
let data: Data = """
[
    {
        "authURL": "https://api.login.aol.com/oauth2/request_auth",
        "issuer": "login.aol.com",
        "scope": "mail-w",
        "tokenURL": "https://api.login.aol.com/oauth2/get_token"
    },
    {
        "authURL": "https://accounts.google.com/o/oauth2/auth",
        "issuer": "accounts.google.com",
        "scope": "https://mail.google.com/ https://www.googleapis.com/auth/contacts https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/carddav",
        "tokenURL": "https://www.googleapis.com/oauth2/v3/token"
    },
    {
        "authURL": "https://api.login.yahoo.com/oauth2/request_auth",
        "issuer": "login.yahoo.com",
        "scope": "mail-w",
        "tokenURL": "https://api.login.yahoo.com/oauth2/get_token"
    }
]
""".data(using: .utf8)!

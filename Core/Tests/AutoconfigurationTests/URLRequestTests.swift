// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Autoconfiguration
import Foundation
import Testing

struct URLRequestTests {
    @Test func token() throws {
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
        let pkce = OAuth2.PKCE(codeVerifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
        let tokenRequest = try URLRequest.token(request, code: "0123456789", pkce: pkce)

        #expect(tokenRequest.httpMethod == "POST")
        #expect(
            tokenRequest.httpBody
                == "client_id=Cl13n+-ID&client_secret=&redirect_uri=com.example:/oauth2redirect&grant_type=authorization_code&code=0123456789&code_verifier=dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
                .data(using: .utf8)
        )
        #expect(tokenRequest.url == URL(string: "https://example.com/token"))
        #expect(tokenRequest.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
    }

    @Test func refreshToken() async throws {
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
        let tokenRequest = try URLRequest.refreshToken(request, refreshToken: "0123456789")

        #expect(tokenRequest.httpMethod == "POST")
        #expect(
            tokenRequest.httpBody
                == "client_id=Cl13n+-ID&client_secret=&redirect_uri=com.example:/oauth2redirect&grant_type=refresh_token&refresh_token=0123456789"
                .data(using: .utf8)
        )
        #expect(tokenRequest.url == URL(string: "https://example.com/token"))
        #expect(tokenRequest.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
    }
}

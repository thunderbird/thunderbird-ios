// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Autoconfiguration
import Foundation
import Testing

struct URLRequestTests {
    //Expect: Send the token request as a POST.
    //Case: When exchanging an authorization code for tokens.
    @Test func token_usesPOST_whenExchangingAuthorizationCode() throws {
        // Arrange
        let configuration = try Self.configuration()
        let pkce = OAuth2.PKCE(codeVerifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
        let expected = "POST"

        // Act
        let actual = try URLRequest.token(configuration, code: "0123456789", pkce: pkce).httpMethod

        // Assert
        #expect(actual == expected)
    }

    //Expect: Form-encode the client, redirect, grant type, code and verifier in the body, with an empty client secret and `+` percent-encoded.
    //Example: The test client ID `Cl13n+-ID` must be sent as `Cl13n%2B-ID`. Sent as-is, the server reads `Cl13n -ID`.
    //Case: When exchanging an authorization code for tokens.
    @Test func token_encodesParametersInBody_whenExchangingAuthorizationCode() throws {
        // Arrange
        let configuration = try Self.configuration()
        let pkce = OAuth2.PKCE(codeVerifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
        let expected =
            "client_id=Cl13n%2B-ID&client_secret=&redirect_uri=com.example:/oauth2redirect&grant_type=authorization_code&code=0123456789&code_verifier=dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
            .data(using: .utf8)

        // Act
        let actual = try URLRequest.token(configuration, code: "0123456789", pkce: pkce).httpBody

        // Assert
        #expect(actual == expected)
    }

    //Expect: Target the token endpoint with no query string.
    //Case: When exchanging an authorization code for tokens.
    @Test func token_targetsTokenEndpoint_whenExchangingAuthorizationCode() throws {
        // Arrange
        let configuration = try Self.configuration()
        let pkce = OAuth2.PKCE(codeVerifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
        let expected = URL(string: "https://example.com/token")

        // Act
        let actual = try URLRequest.token(configuration, code: "0123456789", pkce: pkce).url

        // Assert
        #expect(actual == expected)
    }

    //Expect: Send the refresh request as a POST.
    //Case: When exchanging a refresh token for a new access token.
    @Test func refreshToken_usesPOST_whenExchangingRefreshToken() throws {
        // Arrange
        let configuration = try Self.configuration()
        let expected = "POST"

        // Act
        let actual = try URLRequest.refreshToken(configuration, refreshToken: "0123456789").httpMethod

        // Assert
        #expect(actual == expected)
    }

    //Expect: Form-encode the client, redirect, grant type and refresh token in the body, with an empty client secret and `+` percent-encoded.
    //Example: The test client ID `Cl13n+-ID` must be sent as `Cl13n%2B-ID`. Sent as-is, the server reads `Cl13n -ID`.
    //Case: When exchanging a refresh token for a new access token.
    @Test func refreshToken_encodesParametersInBody_whenExchangingRefreshToken() throws {
        // Arrange
        let configuration = try Self.configuration()
        let expected =
            "client_id=Cl13n%2B-ID&client_secret=&redirect_uri=com.example:/oauth2redirect&grant_type=refresh_token&refresh_token=0123456789"
            .data(using: .utf8)

        // Act
        let actual = try URLRequest.refreshToken(configuration, refreshToken: "0123456789").httpBody

        // Assert
        #expect(actual == expected)
    }

    //Expect: Target the token endpoint with no query string.
    //Case: When exchanging a refresh token for a new access token.
    @Test func refreshToken_targetsTokenEndpoint_whenExchangingRefreshToken() throws {
        // Arrange
        let configuration = try Self.configuration()
        let expected = URL(string: "https://example.com/token")

        // Act
        let actual = try URLRequest.refreshToken(configuration, refreshToken: "0123456789").url

        // Assert
        #expect(actual == expected)
    }

    //Expect: Percent-encode `+` in the form-encoded `code`, so the token endpoint doesn't decode it as a space.
    //Case: When the authorization code contains `+`.
    //Example: Codes and tokens are opaque strings chosen by the provider and may contain `+`. Sent unencoded, the token
    //  endpoint would read a different code than it issued and reject the sign-in.
    @Test func token_encodesPlusInCode_whenCodeContainsPlus() throws {
        // Arrange
        let configuration = try Self.configuration()
        let pkce = OAuth2.PKCE(codeVerifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
        let input = "0123+4567"
        let expected = "0123+4567"

        // Act
        let body = try URLRequest.token(configuration, code: input, pkce: pkce).httpBody
        let actual = body.flatMap { String(data: $0, encoding: .utf8) }?.formValue("code")

        // Assert
        #expect(actual == expected)
    }

    //Expect: Percent-encode `+` in the form-encoded `refresh_token`, so the token endpoint doesn't decode it as a space.
    //Case: When the refresh token contains `+`.
    //Example: Sent unencoded, the token endpoint would read a different refresh token and refuse to renew access, so the
    //  user would be signed out when their access token expired.
    @Test func refreshToken_encodesPlusInRefreshToken_whenTokenContainsPlus() throws {
        // Arrange
        let configuration = try Self.configuration()
        let input = "0123+4567"
        let expected = "0123+4567"

        // Act
        let body = try URLRequest.refreshToken(configuration, refreshToken: input).httpBody
        let actual = body.flatMap { String(data: $0, encoding: .utf8) }?.formValue("refresh_token")

        // Assert
        #expect(actual == expected)
    }
}

extension URLRequestTests {
    static func configuration() throws -> OAuth2.Configuration {
        try OAuth2.Configuration(
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
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Autoconfiguration
import Foundation
import Testing

struct OAuth2Tests {
    //Expect: Generate a 43-character code verifier.
    //Case: When a PKCE pair is created without a verifier.
    @Test func pkceInit_generates43CharacterVerifier_whenCreatedWithoutVerifier() {
        // Arrange
        let expected = 43

        // Act
        let actual = OAuth2.PKCE().codeVerifier.count

        // Assert
        #expect(actual == expected)
    }

    //Expect: Use only the unreserved characters RFC 7636 allows in a code verifier.
    //Case: When a PKCE pair is created without a verifier.
    @Test func pkceInit_generatesUnreservedCharactersOnly_whenCreatedWithoutVerifier() {
        // Arrange
        let allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")

        // Act
        let actual = OAuth2.PKCE().codeVerifier.unicodeScalars

        // Assert
        #expect(actual.allSatisfy { allowedCharacters.contains($0) })
    }

    //Expect: Derive the S256 code challenge given in RFC 7636 Appendix B.
    //Case: When the verifier is the RFC 7636 test vector.
    @Test func pkceInit_derivesRFC7636Challenge_whenVerifierIsTestVector() {
        // Arrange
        let input = Self.testVectorVerifier
        let expected = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"

        // Act
        let actual = OAuth2.PKCE(codeVerifier: input).codeChallenge

        // Assert
        #expect(actual == expected)
    }

    //Expect: Include the PKCE code challenge as the `code_challenge` query item.
    //Case: When the authorization URL is built with a PKCE pair.
    @Test func authURL_includesCodeChallenge_whenPKCEIsProvided() throws {
        // Arrange
        let configuration = try Self.configuration()
        let pkce = OAuth2.PKCE(codeVerifier: Self.testVectorVerifier)
        let expected = pkce.codeChallenge

        // Act
        let actual = Self.queryItem("code_challenge", in: configuration.authURL(hint: "user@example.com", pkce: pkce))

        // Assert
        #expect(actual == expected)
    }

    //Expect: Set the `code_challenge_method` query item to `S256`.
    //Case: When the authorization URL is built with a PKCE pair.
    @Test func authURL_usesS256ChallengeMethod_whenPKCEIsProvided() throws {
        // Arrange
        let configuration = try Self.configuration()
        let pkce = OAuth2.PKCE(codeVerifier: Self.testVectorVerifier)
        let expected = "S256"

        // Act
        let actual = Self.queryItem("code_challenge_method", in: configuration.authURL(hint: "user@example.com", pkce: pkce))

        // Assert
        #expect(actual == expected)
    }

    //Expect: Pass the hint through as the `login_hint` query item.
    //Case: When the authorization URL is built with an email address hint.
    @Test func authURL_includesLoginHint_whenHintIsProvided() throws {
        // Arrange
        let configuration = try Self.configuration()
        let pkce = OAuth2.PKCE(codeVerifier: Self.testVectorVerifier)
        let input = "user@example.com"
        let expected = "user@example.com"

        // Act
        let actual = Self.queryItem("login_hint", in: configuration.authURL(hint: input, pkce: pkce))

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return `false`.
    //Case: When the host doesn't end with any configured host.
    @Test func matches_returnsFalse_whenHostIsUnrelated() throws {
        // Arrange
        let configuration = try Self.configuration(hosts: ["example.com", "examplemail.com"])
        let input = "google.com"

        // Act
        let actual = configuration.matches(input)

        // Assert
        #expect(actual == false)
    }

    //Expect: Return `true`.
    //Case: When the host is a subdomain of a configured host.
    @Test func matches_returnsTrue_whenHostIsSubdomainOfConfiguredHost() throws {
        // Arrange
        let configuration = try Self.configuration(hosts: ["example.com", "examplemail.com"])
        let input = "mail.example.com"

        // Act
        let actual = configuration.matches(input)

        // Assert
        #expect(actual == true)
    }

    //Expect: Return `true`.
    //Case: When the host is exactly a configured host.
    @Test func matches_returnsTrue_whenHostEqualsConfiguredHost() throws {
        // Arrange
        let configuration = try Self.configuration(hosts: ["example.com", "examplemail.com"])
        let input = "examplemail.com"

        // Act
        let actual = configuration.matches(input)

        // Assert
        #expect(actual == true)
    }

    //Expect: Return `false`.
    //Case: When the host is only the end of a configured host (`mail.com` within `examplemail.com`).
    @Test func matches_returnsFalse_whenHostIsSuffixOfConfiguredHost() throws {
        // Arrange
        let configuration = try Self.configuration(hosts: ["example.com", "examplemail.com"])
        let input = "mail.com"

        // Act
        let actual = configuration.matches(input)

        // Assert
        #expect(actual == false)
    }

    //Expect: Decode the scope as a one-element array.
    //Case: When the first provider (AOL) has a single scope.
    @Test func decoderInit_decodesSingleScope_whenScopeHasOneValue() throws {
        // Arrange
        let input = data
        let expected = [
            "mail-w"
        ]

        // Act
        let actual = try JSONDecoder().decode([OAuth2].self, from: input)[0].scope

        // Assert
        #expect(actual == expected)
    }

    //Expect: Split the space-separated scope string into separate scopes, in order.
    //Case: When the second provider (Google) lists four scopes.
    @Test func decoderInit_splitsScopesOnSpaces_whenScopeHasMultipleValues() throws {
        // Arrange
        let input = data
        let expected = [
            "https://mail.google.com/",
            "https://www.googleapis.com/auth/contacts",
            "https://www.googleapis.com/auth/calendar",
            "https://www.googleapis.com/auth/carddav"
        ]

        // Act
        let actual = try JSONDecoder().decode([OAuth2].self, from: input)[1].scope

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the scope for the last entry as well as the first.
    //Case: When the third provider (Yahoo) has a single scope.
    @Test func decoderInit_decodesScopeForLastEntry_whenArrayHasThreeProviders() throws {
        // Arrange
        let input = data
        let expected = [
            "mail-w"
        ]

        // Act
        let actual = try JSONDecoder().decode([OAuth2].self, from: input)[2].scope

        // Assert
        #expect(actual == expected)
    }
}

extension OAuth2Tests {
    /// Code verifier from RFC 7636 Appendix B.
    static let testVectorVerifier: String = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"

    static func configuration(hosts: [String] = []) throws -> OAuth2.Configuration {
        try OAuth2.Configuration(
            authURI: "https://example.com/authorize",
            tokenURI: "https://example.com/token",
            redirectURI: "com.example:/oauth2redirect",
            responseType: "code",
            scope: [
                "mail-w"
            ],
            clientID: "Cl13n+-ID",
            hosts: hosts
        )
    }

    static func queryItem(_ name: String, in url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == name })?.value
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

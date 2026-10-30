// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import CryptoKit

/// OAuth2 endpoints advertised in an Autoconfig document, plus the application-specific configuration
/// (client ID, redirect URI) needed to run an authorization-code flow with PKCE.
public struct OAuth2: Decodable {
    /// Proof Key for Code Exchange (RFC 7636) verifier and its S256 challenge.
    public struct PKCE: Equatable, Sendable {
        /// Random secret sent with the token request.
        public let codeVerifier: String
        /// Base64URL-encoded SHA-256 hash of ``codeVerifier``, sent with the authorization request.
        public let codeChallenge: String

        /// Generate a new verifier from 32 random bytes and derive its challenge.
        public init() {
            var generator = SystemRandomNumberGenerator()
            let bytes = (0..<32).map { _ in
                UInt8.random(in: UInt8.min...UInt8.max, using: &generator)
            }
            self.init(codeVerifier: Data(bytes).base64URLEncodedString())
        }

        init(codeVerifier: String) {
            self.codeVerifier = codeVerifier
            self.codeChallenge = Data(SHA256.hash(data: Data(codeVerifier.utf8))).base64URLEncodedString()
        }
    }

    /// Application-specific OAuth2 client configuration for a provider.
    public struct Configuration: Codable, Equatable, Hashable, Sendable {
        /// Authorization endpoint.
        public let authURI: String
        /// Token endpoint.
        public let tokenURI: String
        /// Redirect URI registered for the client, typically a custom URL scheme.
        public let redirectURI: String
        /// OAuth2 `response_type`, e.g. `code`.
        public let responseType: String
        /// Requested scopes.
        public let scope: [String]
        /// Host-name suffixes matched against a provider's MX hosts; see ``matches(_:)``.
        public let hosts: [String]
        /// Client identifier registered with the provider.
        public let clientID: String

        /// Authorization URL to present to the user, including the PKCE challenge.
        ///
        /// - Parameters:
        ///   - hint: Email address to prepopulate as `login_hint`. Omitted when `nil` or empty.
        ///   - pkce: PKCE pair whose challenge is sent; keep it to complete ``tokenURL(_:pkce:)``.
        /// - Returns: The authorization endpoint URL with the request parameters as query items.
        public func authURL(hint: String? = nil, pkce: PKCE) -> URL {
            var components: URLComponents = URLComponents(string: authURI)!  // Validated during init
            components.queryItems = [
                URLQueryItem(name: "client_id", value: clientID),
                URLQueryItem(name: "redirect_uri", value: redirectURI),
                URLQueryItem(name: "response_type", value: responseType),
                URLQueryItem(name: "scope", value: scope.joined(separator: " ")),
                URLQueryItem(name: "code_challenge", value: pkce.codeChallenge),
                URLQueryItem(name: "code_challenge_method", value: "S256")
            ]
            if let hint, !hint.isEmpty {  // Prepopulate email address for specific user
                components.queryItems?.append(URLQueryItem(name: "login_hint", value: hint))
            }
            return components.url!
        }

        /// Token endpoint URL, with parameters as query items, to exchange an authorization code for tokens.
        ///
        /// Includes an empty `client_secret`, as for a public client. Use `URLRequest.token(_:code:pkce:)` to move
        /// the query into a POST body.
        ///
        /// - Parameters:
        ///   - code: Authorization code returned to the redirect URI.
        ///   - pkce: The pair whose challenge was used in ``authURL(hint:pkce:)``.
        /// - Returns: The token endpoint URL with the request parameters as query items.
        public func tokenURL(_ code: String, pkce: PKCE) -> URL {
            var components: URLComponents = URLComponents(string: tokenURI)!  // Validated during init
            components.queryItems = [
                URLQueryItem(name: "client_id", value: clientID),
                URLQueryItem(name: "client_secret", value: ""),
                URLQueryItem(name: "redirect_uri", value: redirectURI),
                URLQueryItem(name: "grant_type", value: "authorization_code"),
                URLQueryItem(name: "code", value: code),
                URLQueryItem(name: "code_verifier", value: pkce.codeVerifier)
            ]
            return components.url!
        }

        /// Token endpoint URL, with parameters as query items, to exchange a refresh token for a new access token.
        ///
        /// Includes an empty `client_secret`, as for a public client. Use `URLRequest.refreshToken(_:refreshToken:)`
        /// to move the query into a POST body.
        ///
        /// - Parameter refreshToken: Refresh token from a previous ``TokenResponse``.
        /// - Returns: The token endpoint URL with the request parameters as query items.
        public func refreshTokenURL(_ refreshToken: String) -> URL {
            var components: URLComponents = URLComponents(string: tokenURI)!  // Validated during init
            components.queryItems = [
                URLQueryItem(name: "client_id", value: clientID),
                URLQueryItem(name: "client_secret", value: ""),
                URLQueryItem(name: "redirect_uri", value: redirectURI),
                URLQueryItem(name: "grant_type", value: "refresh_token"),
                URLQueryItem(name: "refresh_token", value: refreshToken)
            ]
            return components.url!
        }

        /// Whether `host` ends with any entry in ``hosts``.
        ///
        /// This is a plain suffix comparison, so entries should include a leading dot when a label boundary matters.
        ///
        /// - Parameter host: Host name to test, such as an MX record host.
        /// - Returns: `true` if `host` has any entry in ``hosts`` as a suffix.
        public func matches(_ host: String) -> Bool {
            for _host in hosts {
                guard host.hasSuffix(_host) else { continue }
                return true
            }
            return false
        }

        /// Create a configuration, validating the URIs and required values.
        ///
        /// - Parameters:
        ///   - authURI: Authorization endpoint; must be a valid URL.
        ///   - tokenURI: Token endpoint; must be a valid URL.
        ///   - redirectURI: Redirect URI registered for the client; must not be empty.
        ///   - responseType: OAuth2 `response_type`, e.g. `code`.
        ///   - scope: Requested scopes; must not be empty, and the first must not be empty.
        ///   - clientID: Client identifier registered with the provider; must not be empty.
        ///   - hosts: Host-name suffixes matched against MX hosts. Defaults to none, which never matches.
        /// - Throws: `URLError(.badURL)` if any validation fails. `responseType` isn't validated.
        public init(authURI: String, tokenURI: String, redirectURI: String, responseType: String, scope: [String], clientID: String, hosts: [String] = []) throws {
            guard URL(string: authURI) != nil,
                URL(string: tokenURI) != nil,  // Validate URI strings pass failable URL init
                !redirectURI.isEmpty,
                !scope.isEmpty, !(scope.first ?? "").isEmpty,
                !clientID.isEmpty
            else {
                throw URLError(.badURL)
            }
            self.authURI = authURI
            self.tokenURI = tokenURI
            self.redirectURI = redirectURI
            self.responseType = responseType
            self.scope = scope
            self.hosts = hosts
            self.clientID = clientID
        }

        /// Build a configuration from endpoints discovered via Autoconfig plus application-specific values.
        ///
        /// - Parameters:
        ///   - oauth2: Endpoints and scopes advertised by the provider.
        ///   - redirectURI: Redirect URI registered for the client; must not be empty.
        ///   - responseType: OAuth2 `response_type`, e.g. `code`.
        ///   - clientID: Client identifier registered with the provider; must not be empty.
        /// - Throws: `URLError(.badURL)`, as for the designated initializer.
        public init(_ oauth2: OAuth2, redirectURI: String, responseType: String, clientID: String) throws {
            try self.init(
                authURI: oauth2.authURL.absoluteString,
                tokenURI: oauth2.tokenURL.absoluteString,
                redirectURI: redirectURI,
                responseType: responseType,
                scope: oauth2.scope,
                clientID: clientID
            )
        }
    }

    /// Application-specific OAuth2 configurations, consulted by ``configuration(_:)``.
    ///
    /// Set once at launch, before any lookups; access is not synchronized.
    nonisolated(unsafe) public static var configurations: [Configuration] = []

    /// Find the configured OAuth2 setup for an email address by matching its MX hosts against ``configurations``.
    ///
    /// - Parameter emailAddress: An email address or bare host name; its MX records are queried.
    /// - Returns: The first configuration matching an MX host, checking MX records in the order DNS returned them.
    /// - Throws: `URLError(.unsupportedURL)` if no MX host matches any configuration, or a DNS error.
    public static func configuration(_ emailAddress: String) async throws -> Self.Configuration {
        let records: [MXRecord] = try await DNSResolver.queryMX(emailAddress)
        for record in records {
            for configuration in configurations {
                guard configuration.matches(record.host) else { continue }
                return configuration
            }
        }
        throw URLError(.unsupportedURL)
    }

    /// Authorization endpoint advertised by the provider.
    public let authURL: URL
    /// Token endpoint advertised by the provider.
    public let tokenURL: URL
    /// Scopes advertised by the provider, split from a space-separated string.
    public let scope: [String]
    /// Issuer identifier advertised by the provider.
    public let issuer: String

    // MARK: Decodable
    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer = try decoder.container(keyedBy: Key.self)
        self.tokenURL = try container.decode(URL.self, forKey: .tokenURL)
        self.authURL = try container.decode(URL.self, forKey: .authURL)
        self.issuer = try container.decode(String.self, forKey: .issuer)
        self.scope = try container.decode(String.self, forKey: .scope).components(separatedBy: " ")
    }

    private enum Key: CodingKey {
        case authURL, issuer, scope, tokenURL
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

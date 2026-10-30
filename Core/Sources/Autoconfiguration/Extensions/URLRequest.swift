// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension URLRequest {
    /// POST request exchanging an authorization code for tokens.
    ///
    /// Parameters are sent form-encoded in the body rather than the query string.
    ///
    /// - Parameters:
    ///   - configuration: OAuth2 configuration providing the token endpoint and client details.
    ///   - code: Authorization code returned to the redirect URI.
    ///   - pkce: The PKCE pair whose challenge was used in the authorization request.
    /// - Returns: The configured request.
    /// - Throws: `URLError(.badURL)` if the token URL can't be built.
    public static func token(_ configuration: OAuth2.Configuration, code: String, pkce: OAuth2.PKCE) throws -> Self {
        guard
            var components: URLComponents = URLComponents(
                url: configuration.tokenURL(code, pkce: pkce),
                resolvingAgainstBaseURL: false
            ), let httpBody: Data = components.percentEncodedQuery?.data(using: .utf8)
        else {
            throw URLError(.badURL)
        }
        components.queryItems = nil
        var request: Self = Self(url: components.url!)
        request.httpMethod = "POST"
        request.httpBody = httpBody
        return request
    }

    /// POST request exchanging a refresh token for a new access token.
    ///
    /// Parameters are sent form-encoded in the body rather than the query string.
    ///
    /// - Parameters:
    ///   - configuration: OAuth2 configuration providing the token endpoint and client details.
    ///   - refreshToken: Refresh token from a previous ``TokenResponse``.
    /// - Returns: The configured request.
    /// - Throws: `URLError(.badURL)` if the token URL can't be built.
    public static func refreshToken(_ configuration: OAuth2.Configuration, refreshToken: String) throws -> Self {
        guard
            var components: URLComponents = URLComponents(
                url: configuration.refreshTokenURL(refreshToken),
                resolvingAgainstBaseURL: false
            ), let httpBody: Data = components.percentEncodedQuery?.data(using: .utf8)
        else {
            throw URLError(.badURL)
        }
        components.queryItems = nil
        var request: Self = Self(url: components.url!)
        request.httpMethod = "POST"
        request.httpBody = httpBody
        return request
    }
}

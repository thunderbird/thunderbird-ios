// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Successful OAuth2 token response for an authorization-code exchange (`access_token`, `expires_in`, `refresh_token`).
public struct TokenResponse: Decodable {
    /// Bearer token used to authenticate to the mail server.
    public let accessToken: String
    /// Access token lifetime in seconds.
    public let expiresIn: Int
    /// Token used to obtain a new access token; see ``RefreshTokenResponse``.
    public let refreshToken: String

    // MARK: Decodable
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        expiresIn = try container.decode(Int.self, forKey: .expiresIn)
        refreshToken = try container.decode(String.self, forKey: .refreshToken)
    }

}

/// OAuth2 token response for a refresh-token exchange.
///
/// Unlike ``TokenResponse``, any refresh token in the response is ignored, so callers keep using the existing one.
/// Providers that rotate refresh tokens will invalidate it.
public struct RefreshTokenResponse: Decodable {
    /// Bearer token used to authenticate to the mail server.
    public let accessToken: String
    /// Access token lifetime in seconds.
    public let expiresIn: Int

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        expiresIn = try container.decode(Int.self, forKey: .expiresIn)
    }
}

/// Snake-case keys of the OAuth2 token response.
private enum Key: String, CodingKey {
    case accessToken = "access_token"
    case expiresIn = "expires_in"
    case refreshToken = "refresh_token"
}

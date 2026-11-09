// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Represents an authorization credential for a user, either basic authentication or OAuth.
public enum Authorization: CustomStringConvertible, Equatable {
    /// Basic authorization with username and password.
    case basic(user: String, password: String)
    /// OAuth authorization with access and refresh tokens.
    case oauth(user: String, token: Token, refresh: Token)
    /// No authorization.
    case none

    /// The associated username for this authorization.
    public var user: String {
        switch self {
        case .basic(let user, _), .oauth(let user, _, _): user
        case .none: ""
        }
    }

    /// Formatted value for use in a URLRequest Authorization header.
    public var value: String {
        switch self {
        case .basic: "Basic \(password)"
        case .oauth: "Bearer \(password)"
        case .none: ""
        }
    }

    /// Encoded credential string for secure storage.
    public var password: String {
        switch self {
        case .basic(let user, let password):
            "\(user):\(password)".data(using: .utf8)!.base64EncodedString()
        case .oauth(_, let token, let refreshToken):
            "\(token):\(token.tokenExpiration?.timeIntervalSince1970, default: "0"):\(refreshToken)"
                .data(using: .utf8)!
                .base64EncodedString()
        case .none:
            ""
        }
    }

    /// Whether this authorization is considered expired.
    public var isExpired: Bool {
        switch self {
        case .basic(_, _): false
        case .oauth(_, let token, _): token.isExpired
        case .none: true
        }
    }

    /// The refresh token value, if present.
    public var refreshToken: String? {
        switch self {
        case .oauth(_, _, let refreshToken): refreshToken.value
        case .basic, .none: nil
        }
    }

    /// Initializes an Authorization from a username and password string, decoding as needed.
    ///
    /// - Parameters:
    ///   - user: The username used for authorization.
    ///   - password: The password used for authorization.
    init(user: String, password: String?) {
        let password: String = password ?? ""
        if !user.isEmpty,
            let data: Data = Data(base64Encoded: password),
            let components: [String] = String(data: data, encoding: .utf8)?.components(separatedBy: ":")
        {
            switch components.count {
            case 3:
                let expDate: Date = Date(timeIntervalSince1970: TimeInterval(components[1]) ?? 0)
                self = .oauth(user: user, token: .bearer(components[0], expDate), refresh: .refresh(components[2]))
            case 2:
                self = .basic(user: user, password: components[1])
            default:
                self = .none
            }
        } else {
            self = .none
        }
    }

    /// Required for `CustomStringConvertible` conformance.
    public var description: String { value }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Represents an OAuth token for authentication, either bearer or refresh.
public enum Token: CustomStringConvertible, Equatable {
    /// Bearer access token with its expiration date.
    case bearer(String, Date)
    /// Refresh token.
    case refresh(String)

    /// The raw string value of the token.
    var value: String {
        switch self {
        case .bearer(let token, _), .refresh(let token): token
        }
    }

    /// Whether the token is expired (for bearer tokens only).
    var isExpired: Bool {
        switch self {
        case .bearer(_, let expiration): Date() > expiration
        case .refresh(_): false
        }
    }

    /// Expiration date for bearer tokens, if available.
    var tokenExpiration: Date? {
        switch self {
        case .bearer(_, let expiration): expiration
        case .refresh(_): nil
        }
    }

    /// Initializes a Token from value and expiration.
    public init(value: String, expiration: Date) {
        self = .bearer(value, expiration)
    }

    /// Initializes a refresh Token from a string value.
    public init(value: String) {
        self = .refresh(value)
    }

    // MARK: CustomStringConvertible
    /// String representation of the token.
    public var description: String { value }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Autoconfiguration

/// Supported authentication mechanisms for email accounts.
///
/// Values include password-based auth, OAuth 2.0, and no authentication.
public enum AuthenticationType: String, Codable, CaseIterable, CustomStringConvertible, Identifiable, Sendable {
    case password
    case oauth2 = "OAuth2"
    case none

    public var id: String { rawValue }

    /// Required for `CustomStringConvertible` conformance.
    public var description: String { rawValue }
}

/// Extends `AuthenticationType` with convenience initializers for autoconfiguration types.
extension AuthenticationType {
    /// Convenience initializer for mapping autoconfiguration results to an authentication type.
    ///
    /// - Parameter authentication: The set of supported authentication mechanisms reported by the provider.
    /// Initializes from a list of provider-supported authentication methods, preferring OAuth2 when available.
    init(_ authentication: [EmailProvider.Server.Authentication]) {
        if authentication.contains(.oauth2) {
            self = .oauth2  // Prefer OAuth2
        } else if authentication.contains(.passwordCleartext) {
            self = .password
        } else {
            self = .none
        }
    }
}

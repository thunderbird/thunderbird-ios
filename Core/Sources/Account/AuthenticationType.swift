// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Autoconfiguration

/// Supported authentication mechanisms for email accounts.
///
/// Values include password-based auth, OAuth 2.0, and no authentication.
public enum AuthenticationType: String, Codable, CaseIterable, CustomStringConvertible, Identifiable, Sendable {
    case password
    case oAuth2 = "OAuth2"
    case none

    // MARK: CustomStringConvertible
    /// A human-readable description of the authentication type.
    public var description: String { rawValue }

    // MARK: Identifiable
    /// The stable identifier for the authentication type.
    public var id: String { rawValue }
}

extension AuthenticationType {
    /// Convenience initializer for mapping autoconfiguration results to an authentication type.
    ///
    /// - Parameter authentication: The set of supported authentication mechanisms reported by the provider.
    /// Initializes from a list of provider-supported authentication methods, preferring OAuth2 when available.
    init(_ authentication: [EmailProvider.Server.Authentication]) {
        if authentication.contains(.oAuth2) {
            self = .oAuth2  // Prefer OAuth2
        } else if authentication.contains(.passwordCleartext) {
            self = .password
        } else {
            self = .none
        }
    }
}

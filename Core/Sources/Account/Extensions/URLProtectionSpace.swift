// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Extends `URLProtectionSpace` with helpers for working with secure realms tied to Thunderbird accounts.
extension URLProtectionSpace {
    /// A secure realm for Thunderbird app-owned accounts in the keychain.
    static let account: URLProtectionSpace = URLProtectionSpace(host: "thunderbird.net")

    /// Creates a protection space for a given host using HTTPS and default settings.
    /// - Parameter host: The host provider to retreive from.
    convenience init(host: String) {
        self.init(host: host, port: 0, protocol: "https", realm: nil, authenticationMethod: nil)
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Autoconfiguration

/// Extends arrays of authentication methods with formatting for printing.
extension [EmailProvider.Server.Authentication] {
    /// Join the methods' human-readable descriptions, e.g. `OAuth2/clear-text password`.
    ///
    /// - Parameter separator: String inserted between descriptions. Defaults to none.
    /// - Returns: The joined descriptions, or an empty string if there are no methods.
    func joined(separator: String = "") -> String {
        map { $0.description }.joined(separator: separator)
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension String {
    /// Decode a value from a percent-encoded query string or form body the way servers do
    /// (`application/x-www-form-urlencoded`), where `+` means a space.
    ///
    /// - Parameter name: Name of the parameter to read.
    /// - Returns: The first value for `name`, or `nil` if the string has no such parameter.
    func formValue(_ name: String) -> String? {
        for pair in split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2, parts[0] == name else { continue }
            return parts[1].replacingOccurrences(of: "+", with: " ").removingPercentEncoding
        }
        return nil
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension String {
    /// Decode a value from a percent-encoded query string or form body the way servers do
    /// (`application/x-www-form-urlencoded`), where `+` means a space.
    ///
    /// Tests need this because Foundation doesn't decode that way: `URLComponents.queryItems` reads `user+tag` back
    /// as `user+tag`, so a test using it can't see the bug. A server reads the same text as `user tag`. Decoding with
    /// this helper shows what the server will actually receive.
    ///
    /// For example, `"code=0123+4567".formValue("code")` is `"0123 4567"`, and `"code=0123%2B4567".formValue("code")`
    /// is `"0123+4567"`.
    ///
    /// Browsers apply the same rule: `URLSearchParams` reads `+` as a space, which corrupts Base64 values such as tokens,
    /// while its `append()` encodes `+` as `%2B`. See [MDN: Preserving plus signs](https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams#preserving_plus_signs).
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

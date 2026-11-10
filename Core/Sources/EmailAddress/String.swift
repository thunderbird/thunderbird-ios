// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Extends `String` with Email-related conveniences.
extension String {
    /// Indicates whether the string appears to be a valid email address.
    ///
    /// - Returns: `true` when the string parses as an email address; otherwise, `false`.
    public var isEmailAddress: Bool { EmailAddress(self).isEmailAddress }

    /// Returns the string trimmed of leading and trailing whitespace and newlines.
    ///
    /// - Returns: A new string with surrounding whitespace and newline characters removed.
    func trimmed() -> Self {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Extends `UUID` with strings and multipart boundaries made from its segments.
extension UUID {
    /// Generate a unique, MIME-compatible, US-ASCII data boundary
    ///
    /// - Parameters:
    ///   - segments: How many of the UUID's five segments to use. Defaults to all five.
    ///   - separator: The text between segments. Defaults to `-`.
    ///   - prefix: Text to put before the UUID. It's left out if it isn't ASCII.
    ///   - suffix: Text to put after the UUID. It's left out if it isn't ASCII.
    /// - Returns: A boundary made of the prefix, the UUID segments and the suffix.
    /// - Important: A boundary can be at most 70 characters, and a full UUID is already 36, so a prefix and suffix that
    ///   together are longer than 34 characters make this crash.
    // TODO: Throw `MIMEError.boundaryLength` instead of crashing when the boundary is too long.
    public func dataBoundary(_ segments: Int = 5, separator: String = .separator, prefix: String? = nil, suffix: String? = nil) -> Boundary {
        try! Boundary("\(prefix?.ascii ?? "")\(uuidString(segments, separator: separator))\(suffix?.ascii ?? "")")
    }

    /// The UUID's text with only its first segments, such as `A51D5B17` for one segment.
    ///
    /// - Parameters:
    ///   - segments: How many segments to keep, at least 1. More than five keeps all of them.
    ///   - separator: The text between segments. It falls back to `-` if it isn't ASCII.
    /// - Returns: The kept segments joined by the separator.
    public func uuidString(_ segments: Int, separator: String = .separator) -> String {
        uuidString
            .components(separatedBy: String.separator)
            .prefix(max(segments, 1))
            .joined(separator: separator.ascii ?? .separator)
    }
}

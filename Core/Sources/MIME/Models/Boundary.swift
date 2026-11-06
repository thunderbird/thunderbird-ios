// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Multipart data boundary described in [RFC 2046](https://www.rfc-editor.org/rfc/rfc2046#section-5.1.1)
public struct Boundary: CustomStringConvertible, Equatable, RawRepresentable, Sendable {
    public static var bounds: ClosedRange<Int> { 1...70 }

    /// Valid boundary is 1-70 characters US-ASCII, no trailing white space.
    public init(_ description: String = "") throws {
        guard let description: String = description.trimmed().ascii else {
            throw MIMEError.boundaryNotASCII
        }
        guard Self.bounds.contains(description.count) else {
            throw MIMEError.boundaryLength(description.count)
        }
        self.rawValue = description
    }

    // MARK: CustomStringConvertible
    public var description: String { rawValue }

    // MARK: RawRepresentable
    public let rawValue: String

    public init?(rawValue: String) {
        try? self.init(rawValue)
    }
}

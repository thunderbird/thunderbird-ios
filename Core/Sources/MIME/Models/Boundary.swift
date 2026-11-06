// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// The delimiter that separates the parts of multipart data, described in
/// [RFC 2046](https://www.rfc-editor.org/rfc/rfc2046#section-5.1.1).
///
/// - Note: Only the length and ASCII-ness are checked. RFC 2046 also limits which ASCII characters a boundary may use
///   (no `;` or quotes, for example), and this type accepts them.
public struct Boundary: CustomStringConvertible, Equatable, RawRepresentable, Sendable {
    /// The number of characters a boundary can have: 1 to 70.
    public static var bounds: ClosedRange<Int> { 1...70 }

    /// Valid boundary is 1-70 characters US-ASCII, no trailing white space.
    ///
    /// - Parameter description: The boundary text. Surrounding whitespace is removed before it is checked.
    /// - Throws: `MIMEError.boundaryNotASCII` if the text isn't ASCII, or `MIMEError.boundaryLength` if the trimmed
    ///   text isn't 1 to 70 characters long.
    /// - Important: The default empty value always throws `MIMEError.boundaryLength`, so `Boundary()` can't succeed.
    // TODO: Remove the default value, or generate a boundary when none is given.
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
    /// The boundary text, without the leading `--` that marks it in the data.
    public let rawValue: String

    /// Make a boundary from text, or return `nil` if it isn't a valid boundary.
    public init?(rawValue: String) {
        try? self.init(rawValue)
    }
}

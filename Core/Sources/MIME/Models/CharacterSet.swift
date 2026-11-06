// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// The name of a character encoding, described in [RFC 2045](https://www.rfc-editor.org/rfc/rfc2045#section-2.2).
///
/// A text ``ContentType`` carries one in its `charset` parameter. The name is stored in uppercase and isn't checked
/// against the IANA registry, so any ASCII name is accepted.
///
/// - Note: This isn't Foundation's `CharacterSet`, which describes a set of Unicode characters. Inside this module the
///   name refers to this type.
public struct CharacterSet: CustomStringConvertible, Equatable, RawRepresentable, Sendable {
    /// US-ASCII, the default character encoding.
    public static var ascii: Self { try! Self("US-ASCII") }  // Default character encoding

    /// Make a character set from its name.
    ///
    /// - Parameter description: The charset name, such as `UTF-8`. Defaults to `US-ASCII`.
    /// - Throws: `MIMEError.characterSetNotFound` if the name isn't ASCII or is empty.
    public init(_ description: String = "US-ASCII") throws {
        guard let description: String = description.ascii?.uppercased(), !description.isEmpty else {
            throw MIMEError.characterSetNotFound
        }
        rawValue = description
    }

    // MARK: CustomStringConvertible
    public var description: String { rawValue }

    // MARK: RawRepresentable
    /// The charset name in uppercase.
    public let rawValue: String

    /// Make a character set from a name, or return `nil` if the name isn't valid.
    public init?(rawValue: String) {
        try? self.init(rawValue)
    }
}

/// Extends `CharacterSet` with the character encodings the library names.
extension CharacterSet {
    /// ISO-8859-1 (Latin 1), despite the name, which could suggest the whole ISO-8859 family.
    public static var iso8859: Self { try! Self("ISO-8859-1") }
    /// UTF-8.
    public static var utf8: Self { try! Self("UTF-8") }
}

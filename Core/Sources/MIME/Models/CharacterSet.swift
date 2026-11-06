// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Character encoding described in [RFC 2045](https://www.rfc-editor.org/rfc/rfc2045#section-2.2)
public struct CharacterSet: CustomStringConvertible, Equatable, RawRepresentable, Sendable {
    public static var ascii: Self { try! Self("US-ASCII") }  // Default character encoding

    public init(_ description: String = "US-ASCII") throws {
        guard let description: String = description.ascii?.uppercased(), !description.isEmpty else {
            throw MIMEError.characterSetNotFound
        }
        rawValue = description
    }

    // MARK: CustomStringConvertible
    public var description: String { rawValue }

    // MARK: RawRepresentable
    public let rawValue: String

    public init?(rawValue: String) {
        try? self.init(rawValue)
    }
}

extension CharacterSet {
    public static var iso8859: Self { try! Self("ISO-8859-1") }
    public static var utf8: Self { try! Self("UTF-8") }
}

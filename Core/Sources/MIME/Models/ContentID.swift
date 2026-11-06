// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A message identifier, the same format as a ``ContentID``.
public typealias MessageID = ContentID

/// An identifier for a MIME part or a message, used primarily to associate related MIME parts.
///
/// The text is optionally structured. It is suitable for use as an IMAP Message-ID, too. New IDs are generated
/// [as recommended](https://www.jwz.org/doc/mid.html): `<1762463150.A51D5B17@example.com>`, the time in seconds, a
/// dot, the first part of a UUID, and the host. Described in
/// [RFC 2822](https://www.rfc-editor.org/info/rfc2822/#section-3.6.4).
public struct ContentID: CustomStringConvertible, ExpressibleByStringLiteral, Hashable, Identifiable, Sendable {

    /// Make a new ID in the [recommended format.](https://www.jwz.org/doc/mid.html)
    ///
    /// - Parameters:
    ///   - host: The host to put after the `@`. If it's empty, the ID has no host part.
    ///   - date: The time used for the first part of the ID. Defaults to now.
    ///   - uuid: The source of the unique part of the ID, whose first segment is used. Defaults to a new UUID.
    /// - Important: Swift chooses `init(_ description:)` when only a string is given, so `ContentID("example.com")` is
    ///   the ID `example.com`, not a generated ID with that host. Pass `date:` or `uuid:` to generate one.
    // TODO: Rename one of the two initializers so a host name can't be mistaken for a complete ID.
    public init(_ host: String = "", date: Date = Date(), uuid: UUID = UUID()) {
        let local: String = "\(Int(date.timeIntervalSince1970)).\(uuid.uuidString(1))"
        if !host.isEmpty {
            self.init("<\(local)@\(host)>")
        } else {
            self.init("<\(local)>")
        }
    }

    /// Use a string as the ID.
    ///
    /// - Parameter description: The complete ID, such as `<abc@example.com>`. It isn't checked or given angle brackets.
    ///   An empty string generates a local-only ID from the current date and a new UUID.
    public init(_ description: String) {
        // Empty description generates local-only ID from current date and generated UUID
        self.description = description.isEmpty ? Self().description : description
    }

    // MARK: CustomStringConvertible
    public let description: String

    // MARK: ExpressibleByStringLiteral
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }

    // MARK: Identifiable
    public var id: String { description }
}

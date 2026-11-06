// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public typealias MessageID = ContentID

/// Optionally structured Content-ID, used primarily for associating related MIME parts
/// Suitable for use as IMAP Message-ID, also. Generates new IDs [as recommended](https://www.jwz.org/doc/mid.html): `<1762463150.A51D5B17@example.com>`
/// Described in [RFC 2822](https://www.rfc-editor.org/info/rfc2822/#section-3.6.4)
public struct ContentID: CustomStringConvertible, ExpressibleByStringLiteral, Hashable, Identifiable, Sendable {

    /// Make a new ID in the [recommended format.](https://www.jwz.org/doc/mid.html)
    public init(_ host: String = "", date: Date = Date(), uuid: UUID = UUID()) {
        let local: String = "\(Int(date.timeIntervalSince1970)).\(uuid.uuidString(1))"
        if !host.isEmpty {
            self.init("<\(local)@\(host)>")
        } else {
            self.init("<\(local)>")
        }
    }

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

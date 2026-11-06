// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// MIME header described in [RFC 2045](https://www.rfc-editor.org/info/rfc2045/#section-3)
public struct Header: CustomStringConvertible, Equatable, RawRepresentable, Sendable {
    public static let mimeVersion: Self = try! Self(.mimeVersion, "1.0")

    /// Prepared header names for standard MIME headers
    public enum Name: String, CustomStringConvertible, Sendable {
        case contentDisposition = "Content-Disposition"
        case contentTransferEncoding = "Content-Transfer-Encoding"
        case contentType = "Content-Type"
        case mimeVersion = "MIME-Version"

        // MARK: CustomStringConvertible
        public var description: String { rawValue }
    }

    public let name: Name
    public let value: String

    /// Memberwise initializer checks for ASCII-only value.
    public init(_ name: Name, _ value: String) throws {
        guard let value: String = value.ascii else {
            throw MIMEError.headerValueNotASCII
        }
        self.name = name
        self.value = value
    }

    // MARK: RawRepresentable
    public var rawValue: String { "\(name): \(value)" }

    public init?(rawValue: String) {
        let rawValue: [String] = rawValue.components(separatedBy: ": ").map { $0.trimmed() }
        guard rawValue.count == 2, let name: Name = Name(rawValue: rawValue[0]) else {
            return nil
        }
        try? self.init(name, rawValue[1])
    }

    // MARK: CustomStringConvertible
    public var description: String { rawValue }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// A MIME header, a name and a value, described in [RFC 2045](https://www.rfc-editor.org/info/rfc2045/#section-3).
///
/// Only the four standard MIME headers have a ``Name``. Content-ID, which ``Part`` reads, isn't one of them, so it
/// isn't written back out with a part's other headers.
// TODO: Add Content-ID to `Header.Name` and to `Part.headers`, so a part keeps its `cid:` identifier when it is
// written.
public struct Header: CustomStringConvertible, Equatable, RawRepresentable, Sendable {
    /// The `MIME-Version: 1.0` header that a multipart message carries.
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

    /// Which header this is.
    public let name: Name
    /// The header's value, always ASCII.
    public let value: String

    /// Memberwise initializer checks for ASCII-only value.
    ///
    /// - Parameters:
    ///   - name: The header's name.
    ///   - value: The header's value.
    /// - Throws: `MIMEError.headerValueNotASCII` if the value isn't ASCII.
    public init(_ name: Name, _ value: String) throws {
        guard let value: String = value.ascii else {
            throw MIMEError.headerValueNotASCII
        }
        self.name = name
        self.value = value
    }

    // MARK: RawRepresentable
    /// The header as a line of text: the name, a colon and a space, and the value.
    public var rawValue: String { "\(name): \(value)" }

    /// Read a header from a line of text.
    ///
    /// - Parameter rawValue: A line such as `Content-Type: text/plain`.
    /// - Returns: The header, or `nil` if the name isn't one of the four standard MIME headers, the value isn't
    ///   ASCII, or the line doesn't split into exactly two parts at `: `.
    /// - Important: A value that itself contains `: `, such as `attachment; filename="a: b.pdf"`, makes the line split
    ///   into three parts, so the header is not read.
    // TODO: Split only at the first `: ` so values containing it are kept.
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

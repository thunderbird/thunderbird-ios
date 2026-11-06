// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The body of an email message, described in [RFC 2045](https://www.rfc-editor.org/rfc/rfc2045#section-2.6).
///
/// `Body` contains a single ``Part`` that is either multipart or text ``ContentType``. `Body` encodes and decodes
/// complete plain text or MIME message bodies using its `RawRepresentable` conformance.
///
/// - Important: `description` and ``rawValue`` convert the part's data with a force unwrap, so they crash if the data
///   isn't ASCII.
// TODO: Return an error, or percent-encode, instead of force unwrapping non-ASCII data in `description` and `rawValue`.
// TODO: Nothing outside the MIME tests builds a `Body` from a `Part` yet; the app only reads bodies from IMAP.
public struct Body: CustomStringConvertible, RawRepresentable, Sendable {
    /// The part that makes up the body, either text or multipart with subparts.
    public let part: Part

    /// The headers to send with the body: the part's headers without Content-Disposition, plus MIME-Version if the
    /// body is multipart.
    public var headers: [Header] {
        var headers: [Header] = part.headers.filter { $0.name != .contentDisposition }
        if contentType.isMultipart {
            headers.append(.mimeVersion)
        }
        return headers
    }

    /// The transfer encoding of the body's part, if it declares one.
    public var contentTransferEncoding: ContentTransferEncoding? { part.contentTransferEncoding }
    /// The content type of the body's part.
    public var contentType: ContentType { part.contentType }

    /// Make a body from a part.
    ///
    /// - Parameter part: The part to use as the body.
    /// - Throws: `MIMEError.contentTypeNotPossible` if the part's content type isn't text or multipart.
    public init(part: Part) throws {
        switch part.contentType {
        case .multipart, .text:
            self.part = part
        default:
            throw MIMEError.contentTypeNotPossible(part.contentType)
        }
    }

    /// Read headers and decode body from raw ASCII blob.
    ///
    /// - Parameter description: The raw message body, headers first, then a blank line, then the content.
    /// - Throws: The errors `Part.init(_:)` throws for the text, and `MIMEError.contentTypeNotPossible` if the content
    ///   type isn't text or multipart.
    public init(_ description: String) throws {
        try self.init(part: try Part(description))
    }

    /// Read headers and decode body from raw ASCII data.
    ///
    /// - Parameter description: The raw message body as ASCII bytes.
    /// - Throws: `MIMEError.dataNotDecoded` if the data isn't ASCII, otherwise the errors the `String` initializer
    ///   throws.
    public init(_ description: Data) throws {
        guard let description: String = String(data: description, encoding: .ascii) else {
            throw MIMEError.dataNotDecoded(description, encoding: .ascii)
        }
        try self.init(description)
    }

    // MARK: CustomStringConvertible
    public var description: String { String(data: rawValue, encoding: .ascii)! }

    // MARK: RawRepresentable
    /// The body as ASCII data: each header on its own line, a blank line, then the part's data, with every line ending
    /// in CRLF.
    public var rawValue: Data {
        var data: Data = Data()
        for header in headers {
            data.append("\(header)".data(using: .ascii)!)
            data.append(.crlf)
        }
        data.append(.crlf)
        data.append(part.data)
        data.append(.crlf)
        return data
    }

    /// Read a body from raw data, or return `nil` if it can't be read.
    public init?(rawValue: Data) {
        try? self.init(rawValue)
    }
}

/// Extends `Body` with an empty body and a check for one.
extension Body {
    /// A plain text, US-ASCII body with no content.
    public static var empty: Self { try! Self(part: try! Part(data: "".data(using: .ascii)!, contentType: .text(.plain, .ascii))) }
    /// Whether the body has no content.
    ///
    /// - Important: This is also `true` when the part's data isn't ASCII, because data that can't be read counts as
    ///   empty.
    // TODO: Check `part.data.isEmpty` instead, so a non-ASCII body doesn't report as empty.
    public var isEmpty: Bool { (String(data: part.data, encoding: .ascii) ?? "").isEmpty }
}

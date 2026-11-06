// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// One piece of a MIME message: its headers and its content, described in
/// [RFC 2045](https://www.rfc-editor.org/rfc/rfc2045#section-2.5).
///
/// `Part` can contain data for a single piece of text or binary, or they can themselves be multipart, containing one or
/// more subparts. `Part` encodes and decodes complete plain text or MIME message part using `RawRepresentable`
/// conformance.
///
/// - Important: Reading a part from text (`Part(_:)`) changes the data: CRLF line endings become `\n`, and
///   header unfolding is applied to the whole text, including the content, so a content line that starts with a space
///   and `b`, a space and `<`, or a tab is joined to the line before it (a tab is removed). A part with no Content-Type
///   header can't be read, though RFC 2045 says the type then defaults to `text/plain; charset=us-ascii`. A header
///   whose value contains `: ` is skipped. `description` and ``rawValue`` crash if the data isn't ASCII.
// TODO: Unfold only the header lines, keep the content bytes as they are, and default a missing Content-Type to
// text/plain (#627, #628).
// TODO: Return an error instead of force unwrapping non-ASCII data in `description`.
public struct Part: CustomStringConvertible, RawRepresentable, Sendable {

    /// Instruct mail client to display decoded body part inline, in message, or link as an attachment. Optionally include file name and other metadata for source file.
    public let contentDisposition: ContentDisposition?
    /// How the part's data is encoded, or `nil` if the header is missing (meaning 7-bit ASCII).
    public let contentTransferEncoding: ContentTransferEncoding?
    /// The part's Content-ID, used to refer to it from another part with a `cid:` URL.
    public let contentID: ContentID?
    /// The kind of content the part holds.
    public let contentType: ContentType

    /// The actual part content, encoded as an ASCII string using the transfer encoding specified in the part header; typically base64 or quoted-printable
    public let data: Data

    /// The headers to write for this part: Content-Disposition, Content-Transfer-Encoding and Content-Type, in that
    /// order, leaving out any that are `nil`.
    ///
    /// - Important: ``contentID`` is not included, so a part that is written out loses its Content-ID.
    public var headers: [Header] {
        var headers: [Header] = []
        if let contentDisposition {
            headers.append(try! Header(.contentDisposition, "\(contentDisposition)"))
        }
        if let contentTransferEncoding {
            headers.append(try! Header(.contentTransferEncoding, "\(contentTransferEncoding)"))
        }
        headers.append(try! Header(.contentType, "\(contentType)"))
        return headers
    }

    /// Multipart data decoded into parts
    ///
    /// The data is split at every `--` followed by the boundary, whether or not it starts a line, the text before the
    /// first and after the last boundary is dropped, and each subpart is read with `Part(_:)` after its surrounding
    /// whitespace is trimmed.
    ///
    /// - Throws: `MIMEError.contentTypeNotMultipart` if the part isn't multipart, or `MIMEError.dataNotDecoded` if the
    ///   data isn't ASCII or has no subparts, plus any error reading a subpart.
    public var parts: [Self] {
        get throws {
            switch contentType {
            case .multipart(_, let boundary):
                guard
                    let parts: [String] = String(data: data, encoding: .ascii)?
                        .components(separatedBy: "--\(boundary)")
                        .dropFirst().dropLast(),
                    !parts.isEmpty
                else {
                    throw MIMEError.dataNotDecoded(data, encoding: .ascii)
                }
                return try parts.map { try Self($0.trimmed()) }
            default:
                throw MIMEError.contentTypeNotMultipart
            }
        }
    }

    /// Encode multiple data parts  into a single part.
    ///
    /// - Parameters:
    ///   - parts: The subparts, each written after a boundary line.
    ///   - contentType: A multipart type whose boundary separates the subparts. Defaults to `multipart/mixed` with a
    ///     new random boundary.
    /// - Throws: `MIMEError.contentTypeNotPossible` if the type isn't multipart, or `MIMEError.dataNotFound` if there
    ///   are no subparts.
    // TODO: Nothing outside the MIME tests builds a part from subparts yet; the app only reads messages.
    public init(parts: [Self], contentType: ContentType = .multipart(.mixed)) throws {
        switch contentType {
        case .multipart(_, let boundary):
            let data: Data = try parts.data(using: boundary)
            self.init(data: data, contentType: contentType)
        default:
            throw MIMEError.contentTypeNotPossible(contentType)
        }
    }

    /// Read headers and decode body part from raw ASCII blob.
    ///
    /// Only Content-Disposition, Content-Transfer-Encoding, Content-Type and Content-ID are kept, and header names are
    /// matched without regard to case. The content is everything after the first blank line, trimmed.
    ///
    /// - Parameter description: The part as text: header lines, a blank line, then the content.
    /// - Throws: `MIMEError.dataNotFound` if there is no blank line, or `MIMEError.dataNotDecoded` if there's no
    ///   readable Content-Type header or the content isn't ASCII.
    public init(_ description: String) throws {
        let description: String =
            description
            .replacingOccurrences(of: crlf, with: "\n")
            .replacingOccurrences(of: "\n b", with: " b")  // Handle soft wrap caused by long data boundary
            .replacingOccurrences(of: "\n <", with: " <")  // Handle soft wrap caused by long email address label
            .replacingOccurrences(of: "\n\t", with: "")
        let components: [String] = description.components(separatedBy: "\n")
        guard let index: Int = components.firstIndex(of: "") else {
            throw MIMEError.dataNotFound
        }
        var contentDisposition: ContentDisposition?
        var contentTransferEncoding: ContentTransferEncoding?
        var contentType: ContentType?
        var contentID: ContentID?
        for component in components[0..<index] {
            let header: [String] = component.components(separatedBy: ": ").map { $0.trimmed() }
            guard header.count == 2 else { continue }
            switch header[0].lowercased() {  // MIME headers are case-sensitive, but no harm in fuzzy matching
            case "content-disposition":
                contentDisposition = ContentDisposition(rawValue: header[1])
            case "content-transfer-encoding":
                contentTransferEncoding = ContentTransferEncoding(rawValue: header[1])
            case "content-type":
                contentType = ContentType(rawValue: header[1])
            case "content-id":
                contentID = ContentID(header[1])
            default:
                continue
            }
        }
        guard let data: Data = components.dropFirst(index).joined(separator: "\n").trimmed().data(using: .ascii),
            let contentType
        else {
            throw MIMEError.dataNotDecoded(description.data(using: .ascii) ?? Data(), encoding: .ascii)
        }
        self.init(
            data: data,
            contentDisposition: contentDisposition,
            contentTransferEncoding: contentTransferEncoding,
            contentID: contentID,
            contentType: contentType
        )
    }

    /// Read headers and decode body from raw ASCII data.
    ///
    /// - Parameter description: The part as ASCII bytes.
    /// - Throws: `MIMEError.dataNotDecoded` if the bytes aren't ASCII, otherwise the errors the `String` initializer
    ///   throws.
    public init(_ description: Data) throws {
        guard let description: String = String(data: description, encoding: .ascii) else {
            throw MIMEError.dataNotDecoded(description, encoding: .ascii)
        }
        try self.init(description)
    }

    /// Make a part from its content and headers.
    ///
    /// - Parameters:
    ///   - data: The content, already encoded as ASCII with `contentTransferEncoding`.
    ///   - contentDisposition: How to present the part, if it's an attachment or inline.
    ///   - contentTransferEncoding: How the content is encoded.
    ///   - contentID: The part's identifier for `cid:` references.
    ///   - contentType: The kind of content.
    public init(
        data: Data,
        contentDisposition: ContentDisposition? = nil,
        contentTransferEncoding: ContentTransferEncoding? = nil,
        contentID: ContentID? = nil,
        contentType: ContentType
    ) {
        self.contentDisposition = contentDisposition
        self.contentTransferEncoding = contentTransferEncoding
        self.contentID = contentID
        self.contentType = contentType
        self.data = data
    }

    // MARK: CustomStringConvertible
    public var description: String { String(data: rawValue, encoding: .ascii)! }

    // MARK: RawRepresentable
    /// The part as ASCII data: each header on its own line, a blank line, then the content, with every line ending in
    /// CRLF.
    public var rawValue: Data {
        var data: Data = Data()
        for header in headers {
            data.append("\(header)".data(using: .ascii)!)
            data.append(.crlf)
        }
        data.append(.crlf)
        data.append(self.data)
        data.append(.crlf)
        return data
    }

    /// Read a part from raw data, or return `nil` if it can't be read.
    public init?(rawValue: Data) {
        try? self.init(rawValue)
    }
}

/// Extends arrays of ``Part`` with writing them as multipart content.
extension [Part] {
    /// The parts written one after another, each after a `--` boundary line, ending with the closing `--` line.
    ///
    /// - Parameter boundary: The boundary that separates the parts.
    /// - Throws: `MIMEError.dataNotFound` if the array is empty.
    func data(using boundary: Boundary) throws -> Data {
        guard !isEmpty else {
            throw MIMEError.dataNotFound
        }
        var data: Data = Data()
        data.append(.crlf)
        for part in self {
            data.append("--\(boundary)".data(using: .ascii)!)
            data.append(.crlf)
            data.append(part.rawValue)
        }
        data.append("--\(boundary)--".data(using: .ascii)!)
        data.append(.crlf)
        return data
    }
}

/// Extends `Data` with the line ending used in MIME data.
extension Data {
    /// A carriage return and line feed as bytes.
    static let crlf: Self = String.crlf.data(using: .ascii)!
}

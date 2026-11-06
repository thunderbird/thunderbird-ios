// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Multipart body element described in [RFC 2045](https://www.rfc-editor.org/rfc/rfc2045#section-2.6)
///
/// `Body` contains a single ``Part`` that is either multipart or text ``ContentType``.
/// `Body` encodes and decodes complete plain text or MIME message bodies using `RawRepresentable` conformance.
public struct Body: CustomStringConvertible, RawRepresentable, Sendable {
    public let part: Part

    public var headers: [Header] {
        var headers: [Header] = part.headers.filter { $0.name != .contentDisposition }
        if contentType.isMultipart {
            headers.append(.mimeVersion)
        }
        return headers
    }

    public var contentTransferEncoding: ContentTransferEncoding? { part.contentTransferEncoding }
    public var contentType: ContentType { part.contentType }

    public init(part: Part) throws {
        switch part.contentType {
        case .multipart, .text:
            self.part = part
        default:
            throw MIMEError.contentTypeNotPossible(part.contentType)
        }
    }

    /// Read headers and decode body from raw ASCII blob.
    public init(_ description: String) throws {
        try self.init(part: try Part(description))
    }

    /// Read headers and decode body from raw ASCII data.
    public init(_ description: Data) throws {
        guard let description: String = String(data: description, encoding: .ascii) else {
            throw MIMEError.dataNotDecoded(description, encoding: .ascii)
        }
        try self.init(description)
    }

    // MARK: CustomStringConvertible
    public var description: String { String(data: rawValue, encoding: .ascii)! }

    // MARK: RawRepresentable
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

    public init?(rawValue: Data) {
        try? self.init(rawValue)
    }
}

extension Body {
    public static var empty: Self { try! Self(part: try! Part(data: "".data(using: .ascii)!, contentType: .text(.plain, .ascii))) }
    public var isEmpty: Bool { (String(data: part.data, encoding: .ascii) ?? "").isEmpty }
}

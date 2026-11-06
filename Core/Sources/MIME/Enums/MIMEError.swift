// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The errors thrown when reading or writing MIME data.
public enum MIMEError: Error, CustomStringConvertible, Equatable {
    /// A multipart boundary has this many characters, which is outside ``Boundary/bounds``.
    case boundaryLength(Int)
    /// A multipart boundary isn't ASCII.
    case boundaryNotASCII
    /// A character set name is empty or isn't ASCII.
    case characterSetNotFound
    /// A Content-Disposition value doesn't start with a disposition type the library knows.
    case contentDispositionNotFound
    /// A Content-Type value isn't `type/subtype` with a known type.
    case contentTypeNotFound
    /// Subparts were requested from a part that isn't multipart.
    case contentTypeNotMultipart
    /// The content type can't be used here, for example a body that is neither text nor multipart.
    case contentTypeNotPossible(ContentType)
    /// Data couldn't be decoded as text. Besides undecodable content, this is also thrown for a part with no
    /// Content-Type header, and for a multipart part with no subparts, though its message says "Multipart data".
    case dataNotDecoded(Data, encoding: String.Encoding? = nil)
    /// There was no data to work with, for example a part with no blank line after its headers.
    case dataNotFound
    /// Data has an `=` that isn't followed by two hexadecimal digits, so it isn't valid quoted-printable.
    case dataNotQuotedPrintable
    /// A date string couldn't be read as an RFC 822 date.
    case dateNotDecoded(String)
    /// Not thrown by the library today.
    case headerNameNotFound
    /// A header, such as an RFC 2047 encoded word, couldn't be decoded.
    case headerNotDecoded(String)
    /// A header value or a URI built from an ID isn't ASCII, or isn't a valid URL.
    case headerValueNotASCII

    // MARK: CustomStringConvertible
    public var description: String {
        switch self {
        case .boundaryLength(let length): "Multipart data boundary length \(length) outside of bounds \(Boundary.bounds)"
        case .boundaryNotASCII: "Multipart data boundary not ASCII"
        case .characterSetNotFound: "Character set not found"
        case .contentDispositionNotFound: "Content disposition not found"
        case .contentTypeNotFound: "Content type not found"
        case .contentTypeNotMultipart: "Content type not multipart"
        case .contentTypeNotPossible(let contentType): "Content type not possible: \(contentType)"
        case .dataNotDecoded(let data, _): "Multipart data not decoded: \(String(data: data, encoding: .ascii) ?? "�")"
        case .dataNotFound: "Multipart data not found"
        case .dataNotQuotedPrintable: "Data not quoted-printable"
        case .dateNotDecoded(let string): "Date not decoded: \(string)"
        case .headerNameNotFound: "Header name not found"
        case .headerNotDecoded(let string): "Header not decoded: \(string)"
        case .headerValueNotASCII: "Header value not ASCII"
        }
    }
}

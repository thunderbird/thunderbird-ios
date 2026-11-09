// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A [media content type](https://www.iana.org/assignments/media-types/media-types.xhtml), such as `text/plain`, with
/// the base types enumerated and the subtype held as a string.
///
/// Subtypes aren't checked against the registry, and are stored in lowercase when read from a header.
public enum ContentType: CustomStringConvertible, Equatable, RawRepresentable, Sendable {
    case application(String)
    case audio(String)
    case example(String)
    case font(String)
    case haptics(String)
    case image(String)
    case message(String)
    case model(String)
    /// Multipart content with its subtype and the ``Boundary`` that separates the parts.
    ///
    /// The boundary defaults to a new random one each time the case is created without it.
    case multipart(String, Boundary = UUID().dataBoundary())
    /// Text with its subtype and, if the header gave a valid one, its character set.
    case text(String, CharacterSet? = nil)
    case video(String)

    /// The part after the slash, such as `plain` in `text/plain`.
    public var subtype: String {
        switch self {
        case .application(let subtype),
            .audio(let subtype),
            .example(let subtype),
            .font(let subtype),
            .haptics(let subtype),
            .image(let subtype),
            .message(let subtype),
            .model(let subtype),
            .multipart(let subtype, _),
            .text(let subtype, _),
            .video(let subtype):
            subtype
        }
    }

    /// Whether the type is multipart.
    public var isMultipart: Bool {
        switch self {
        case .multipart: true
        default: false
        }
    }

    /// The boundary of a multipart type, or `nil` for any other type.
    public var boundary: Boundary? {
        switch self {
        case .multipart(_, let boundary): boundary
        default: nil
        }
    }

    /// The character set of a text type, or `nil` for any other type or a text type with no valid charset.
    public var charset: CharacterSet? {
        switch self {
        case .text(_, let charset): charset
        default: nil
        }
    }

    /// Read a content type from header text.
    ///
    /// - Parameter description: The header value, such as `multipart/mixed; boundary="abc"` or
    ///   `text/plain; charset=utf-8`. The type and subtype are matched without regard to case.
    /// - Throws: `MIMEError.contentTypeNotFound` if the value isn't `type/subtype` with a known type. For multipart,
    ///   the boundary errors from ``Boundary``, including `MIMEError.boundaryLength` if the header has no boundary.
    public init(_ description: String) throws {
        let rawValue: [String] =
            description
            .components(separatedBy: ";")[0]
            .lowercased()
            .trimmed()
            .components(separatedBy: "/")
        guard rawValue.count == 2, !rawValue[1].isEmpty else {
            throw MIMEError.contentTypeNotFound
        }
        switch rawValue[0] {
        case Self.application("").value:
            self = .application(rawValue[1])
        case Self.audio("").value:
            self = .audio(rawValue[1])
        case Self.example("").value:
            self = .example(rawValue[1])
        case Self.font("").value:
            self = .font(rawValue[1])
        case Self.haptics("").value:
            self = .haptics(rawValue[1])
        case Self.image("").value:
            self = .image(rawValue[1])
        case Self.message("").value:
            self = .message(rawValue[1])
        case Self.model("").value:
            self = .model(rawValue[1])
        case Self.multipart("").value:
            let boundary: Boundary = try Boundary(description.parameters["boundary"] ?? "")
            self = .multipart(rawValue[1], boundary)
        case Self.text("").value:
            self = .text(rawValue[1], try? CharacterSet(description.parameters["charset"] ?? ""))
        case Self.video("").value:
            self = .video(rawValue[1])
        default:
            throw MIMEError.contentTypeNotFound
        }
    }

    var value: String {
        switch self {
        case .application: "application"
        case .audio: "audio"
        case .example: "example"
        case .font: "font"
        case .haptics: "haptics"
        case .image: "image"
        case .message: "message"
        case .model: "model"
        case .multipart: "multipart"
        case .text: "text"
        case .video: "video"
        }
    }

    // MARK: CustomStringConvertible
    public var description: String { rawValue }

    // MARK: RawRepresentable
    /// The header value: `type/subtype`, followed by `; ` and the quoted `boundary` or `charset` when there is one.
    public var rawValue: String {
        var rawValue: [String] = [
            "\(value)/\(subtype)"
        ]
        if let boundary {
            rawValue.append("boundary=\"\(boundary)\"")
        }
        if let charset {
            rawValue.append("charset=\"\(charset)\"")
        }
        return rawValue.joined(separator: "; ")
    }

    public init?(rawValue: String) {
        try? self.init(rawValue)
    }
}

/// Extends `String` with the names of the standard multipart and text subtypes, for building a ``ContentType``.
extension String {

    // Standard multipart subtypes
    public static var alternative: Self { "alternative" }
    public static var mixed: Self { "mixed" }
    public static var related: Self { "related" }

    // Standard text subtypes
    public static var plain: Self { "plain" }
    public static var html: Self { "html" }
}

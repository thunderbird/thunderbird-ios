// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// [Media content types](https://www.iana.org/assignments/media-types/media-types.xhtml) with base types enumerated
public enum ContentType: CustomStringConvertible, Equatable, RawRepresentable, Sendable {
    case application(String)
    case audio(String)
    case example(String)
    case font(String)
    case haptics(String)
    case image(String)
    case message(String)
    case model(String)
    case multipart(String, Boundary = UUID().dataBoundary())
    case text(String, CharacterSet? = nil)
    case video(String)

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

    public var isMultipart: Bool {
        switch self {
        case .multipart: true
        default: false
        }
    }

    public var boundary: Boundary? {
        switch self {
        case .multipart(_, let boundary): boundary
        default: nil
        }
    }

    public var charset: CharacterSet? {
        switch self {
        case .text(_, let charset): charset
        default: nil
        }
    }

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

extension String {

    // Standard multipart subtypes
    public static var alternative: Self { "alternative" }
    public static var mixed: Self { "mixed" }
    public static var related: Self { "related" }

    // Standard text subtypes
    public static var plain: Self { "plain" }
    public static var html: Self { "html" }
}

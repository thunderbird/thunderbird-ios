// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Multipart part content disposition and parameters described in [RFC 2183](https://www.rfc-editor.org/rfc/rfc2183)
///
/// Instruct mail client to display decoded body part inline, in message, or link as an attachment. Optionally include metadata for source file.
public enum ContentDisposition: CustomStringConvertible, Equatable, RawRepresentable, Sendable {
    public struct File: CustomStringConvertible, RawRepresentable, Sendable {

        /// Suggested attachment filename and extension; expressed in ASCII characters
        public let filename: String?
        public let creationDate: Date?
        public let modificationDate: Date?
        public let readDate: Date?

        /// Approximate attachment file size in bytes; i.e.,  `Data.count`
        public let size: Int?  // Bytes (`Data.count`)

        /// Decode `File`from `ContentDisposition` parameter string.
        public init(_ description: String) {
            lazy var formatter: RFC822DateFormatter = RFC822DateFormatter()
            let parameters: [String: String] = description.parameters
            self.init(
                filename: parameters[.filename],
                creationDate: try? formatter.date(from: parameters[.creationDate] ?? ""),
                modificationDate: try? formatter.date(from: parameters[.modificationDate] ?? ""),
                readDate: try? formatter.date(from: parameters[.readDate] ?? ""),
                size: Int(parameters[.size] ?? "")
            )
        }

        public init(
            filename: String? = nil,
            creationDate: Date? = nil,
            modificationDate: Date? = nil,
            readDate: Date? = nil,
            size: Int? = nil
        ) {
            self.filename = !(filename?.ascii ?? "").isEmpty ? filename : nil  // Prevent empty name
            self.creationDate = creationDate
            self.modificationDate = modificationDate
            self.readDate = readDate
            self.size = (size ?? 0) > 0 ? size : nil  // Prevent zero-byte size
        }

        // MARK: CustomStringConvertible
        public var description: String { rawValue }

        // MARK: RawRepresentable
        public var rawValue: String {
            lazy var formatter: RFC822DateFormatter = RFC822DateFormatter()
            var rawValue: [String] = []
            if let filename {
                rawValue.append("\(String.filename)=\"\(filename)\"")
            }
            if let creationDate {
                rawValue.append("\(String.creationDate)=\"\(formatter.string(from: creationDate))\"")
            }
            if let modificationDate {
                rawValue.append("\(String.modificationDate)=\"\(formatter.string(from: modificationDate))\"")
            }
            if let readDate {
                rawValue.append("\(String.readDate)=\"\(formatter.string(from: readDate))\"")
            }
            if let size {
                rawValue.append("\(String.size)=\"\(size)\"")
            }
            return rawValue.joined(separator: "; ")
        }

        public init?(rawValue: String) {
            self.init(rawValue)
        }
    }

    case attachment(File)
    case inline(File)
    case extensionToken

    public static var attachment: Self { .attachment(File()) }
    public static var inline: Self { .inline(File()) }

    public var file: File? {
        switch self {
        case .attachment(let file), .inline(let file): file
        default: nil
        }
    }

    public init(_ description: String) throws {
        switch description.components(separatedBy: ";")[0].lowercased().trimmed() {
        case Self.attachment.value:
            self = .attachment(File(description))
        case Self.inline.value:
            self = .inline(File(description))
        case Self.extensionToken.value:
            self = .extensionToken
        default:
            throw MIMEError.contentDispositionNotFound
        }
    }

    var value: String {
        switch self {
        case .attachment: "attachment"
        case .inline: "inline"
        case .extensionToken: "extension-token"
        }
    }

    // MARK: CustomStringConvertible
    public var description: String { rawValue }

    // MARK: RawRepresentable
    public var rawValue: String {
        switch self {
        case .attachment(let file), .inline(let file):
            !file.rawValue.isEmpty ? "\(value); \(file.rawValue)" : value
        case .extensionToken:
            value
        }
    }

    public init?(rawValue: String) {
        try? self.init(rawValue)
    }
}

private extension String {
    static var filename: Self { "filename" }
    static var creationDate: Self { "creation-date" }
    static var modificationDate: Self { "modification-date" }
    static var readDate: Self { "read-date" }
    static var size: Self { "size" }
}

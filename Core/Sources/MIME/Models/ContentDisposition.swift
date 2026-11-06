// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// How a multipart part should be presented, with its file parameters, described in
/// [RFC 2183](https://www.rfc-editor.org/rfc/rfc2183).
///
/// Instruct mail client to display decoded body part inline, in message, or link as an attachment. Optionally include
/// metadata for source file.
///
/// - Important: The parameters are read with `String.parameters`, which has limits. An
///   apostrophe is removed from a value (`Bob's report.pdf` becomes `Bobs report.pdf`), a `;` inside a quoted file name
///   cuts the name short, spaces around `=` break the value, and RFC 2231 extended names (`filename*=UTF-8''...`) are
///   ignored, so a non-ASCII file name is lost.
// TODO: Parse parameters as quoted strings (RFC 2045 and RFC 2231) instead of removing quotes and splitting on
// `;` (#629).
public enum ContentDisposition: CustomStringConvertible, Equatable, RawRepresentable, Sendable {
    /// Metadata about the file a part came from: its name, dates and size.
    public struct File: CustomStringConvertible, RawRepresentable, Sendable {

        /// Suggested attachment filename and extension; expressed in ASCII characters
        public let filename: String?
        /// When the file was created, from the `creation-date` parameter.
        public let creationDate: Date?
        /// When the file was last modified, from the `modification-date` parameter.
        public let modificationDate: Date?
        /// When the file was last read, from the `read-date` parameter.
        public let readDate: Date?

        /// Approximate attachment file size in bytes; i.e.,  `Data.count`
        public let size: Int?  // Bytes (`Data.count`)

        /// Decode `File`from `ContentDisposition` parameter string.
        ///
        /// - Parameter description: The header value, such as `attachment; filename="a.pdf"; size=1024`. Parameters
        ///   that are missing or can't be read, including dates that aren't RFC 822, leave that property `nil`.
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

        /// Make file metadata from its parts.
        ///
        /// - Parameters:
        ///   - filename: The suggested name. It's dropped (set to `nil`) if it's empty or isn't ASCII.
        ///   - creationDate: When the file was created.
        ///   - modificationDate: When the file was last modified.
        ///   - readDate: When the file was last read.
        ///   - size: The size in bytes. It's dropped if it isn't greater than zero.
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
        /// The parameters as header text, such as `filename="a.pdf"; size="1024"`, separated by `; `, with dates in
        /// RFC 822 format. Empty if no parameter is set.
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

        /// Read file metadata from header text. Never returns `nil`.
        public init?(rawValue: String) {
            self.init(rawValue)
        }
    }

    /// The part is a file the user can save or open, with its metadata.
    case attachment(File)
    /// The part is shown in the body of the message, with its metadata.
    case inline(File)
    /// The literal disposition type `extension-token`.
    ///
    /// - Important: RFC 2183 allows any other extension token as a disposition type, such as `form-data`, but only the
    ///   exact text `extension-token` is recognized, so other values throw `MIMEError.contentDispositionNotFound`.
    // TODO: Accept other extension tokens, or rename this case so it isn't mistaken for the RFC's placeholder (#631).
    case extensionToken

    /// An attachment with no file metadata.
    public static var attachment: Self { .attachment(File()) }
    /// An inline part with no file metadata.
    public static var inline: Self { .inline(File()) }

    /// The file metadata, or `nil` for ``extensionToken``.
    public var file: File? {
        switch self {
        case .attachment(let file), .inline(let file): file
        default: nil
        }
    }

    /// Read a disposition from header text.
    ///
    /// - Parameter description: The header value, such as `attachment; filename="a.pdf"`. The type is matched without
    ///   regard to case.
    /// - Throws: `MIMEError.contentDispositionNotFound` if the type isn't `attachment`, `inline` or `extension-token`.
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
    /// The header value: the type, followed by `; ` and the file parameters when there are any.
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

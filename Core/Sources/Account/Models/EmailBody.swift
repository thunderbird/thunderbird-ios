// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import JMAP
import MIME

/// Format HTML body value with media attachments inlined as base64 data.
public enum HTMLFormat: String, CustomStringConvertible {
    case inlineAttachments = "base64-encoded inline media attachments"
    case stripped = "HTML tags stripped"
    case none = "unmodified source"

    /// Required for `CustomStringConvertible` conformance.
    public var description: String { rawValue }
}

/// The `EmailBody` struct represents the body of an email message.
/// It supports plain text and HTML formatted content, along with file attachments.
/// This type provides multiple formats to represent the email body content, including plain text, HTML, and multipart structures.
public struct EmailBody: CustomStringConvertible, Sendable {
    /// Every ``EmailAttachment`` decoded from `MIME.Body`, including both `ContentDisposition.attached` and `.inline`
    public let attachments: [EmailAttachment]

    /// Plain-text only or alternative message body
    public let text: String?

    /// HTML source decoded from message body with formatting options
    ///
    /// By default, related media attachments are inlined as base64-encoded data attributes`.
    public func html(_ format: HTMLFormat = .inlineAttachments) -> String? {
        switch format {
        case .inlineAttachments: _html?.inlining(attachments: attachments)
        case .stripped: _html?.htmlTagsStripped().htmlEntitiesDecoded()
        case .none: _html
        }
    }

    /// Plain text excerpt or summary of body contents, currently limited to server-provided values, described in [RFC 8970](https://www.rfc-editor.org/info/rfc8970)
    public var preview: String? {
        // TODO: For messages without a server-provided preview, derive excerpt locally
        _preview
    }

    /// Initializes a new `EmailBody`.
    /// - Parameters:
    ///   - html: An optional HTML formatted content.
    ///   - text: The plain text content of the email.
    ///   - attachments: The list of file attachments.
    ///   - preview: The plain textsummary of the email body.
    public init(
        html: String? = nil,
        text: String? = nil,
        attachments: [EmailAttachment] = [],
        preview: String? = nil
    ) {
        self.attachments = attachments
        self.text = text
        _preview = preview
        _html = html
    }

    private let _preview: String?
    private let _html: String?

    /// Required for `CustomStringConvertible` conformance.
    public var description: String {
        text ?? preview ?? ""
    }
}

/// Extends `EmailBody` with custom initializers from different Email types.
extension EmailBody {
    /// Initializes a new `EmailBody` from a `MIME.Body` instance.
    /// - Parameter body: The `MIME.Body` instance to convert.
    /// - Throws: If the conversion fails due to the body being nil or empty.
    init(body: MIME.Body?) throws {
        guard let body, !body.isEmpty else {
            throw AccountError.mime(.dataNotFound)
        }
        let components: MIME.Part.Components = try body.part.components()
        let html: String? = !components.html.isEmpty ? components.html.joined() : nil
        let text: String? = !components.text.isEmpty ? components.text.joined() : nil
        let preview: String? = nil  // TODO: Generate preview text
        self.init(html: html, text: text, attachments: components.0, preview: preview)
    }

    /// Initializes a new `EmailBody` from a `JMAP.Email` instance.
    /// - Parameter body: The `JMAP.Email` instance to convert.
    /// - Throws: Always throws, JMAP implementation incomplete.
    init(email: JMAP.Email) throws {
        // TODO: JMAP email body decoding and assembly not implemented
        throw URLError(.cancelled)
    }
}

/// Extends `MIME.Body` with a computed property to determine if it is empty.
extension MIME.Body {
    var isEmpty: Bool { part.data.count < 1 }
}

/// Extends `MIME.Part` to support additional decoding options.
extension MIME.Part {
    /// A typealias for the components that form a multipart MIME message.
    typealias Components = ([EmailAttachment], html: [String], text: [String])

    /// Recursively decodes and collect all subparts into flattened component arrays
    ///
    /// - Parameter appendedTo: An optional array to append the components to.
    /// - Throws: An error if any part cannot be traversed.
    /// - Returns: An array of components representing the MIME part and its nested parts.
    func components(appendedTo components: Components? = nil) throws -> Components {
        var components: Components = components ?? ([], [], [])
        do {
            switch contentType {
            case .multipart:
                for part in try parts {
                    components = try part.components(appendedTo: components)
                }
            case .text(let subtype, let characterSet):
                let string: String = try String(
                    contentTransferEncoding,
                    data: data,
                    encoding: characterSet?.encoding ?? .utf8
                )
                switch subtype {
                case .html:
                    components.html.append(string)
                case .plain:
                    fallthrough
                // All non-HTML email is plain text
                default:
                    components.text.append(string)
                }
            case .message:
                // Single `message/rfc822` type identifier exists for type `message`
                // "No encoding other than 7bit, 8bit, or binary is permitted for messages or parts of type message"
                // https://www.w3.org/Protocols/rfc1341/7_3_Message.html
                if let body: Body = try? Body(data) {
                    // TODO: Handle forwarded/attached message
                    print(body)
                } else if let text: String = try? String(contentTransferEncoding, data: data, encoding: .ascii) {
                    // TODO: Handle inline plain text message
                    print(text)
                }
            default:
                components.0.append(
                    EmailAttachment(
                        data: try data.decoded(from: contentTransferEncoding),
                        contentType: contentType,
                        contentDisposition: contentDisposition,
                        contentID: contentID
                    ))
            }
        } catch {
            throw error
        }
        // TODO: Encode inline attachments into HTML as base64 strings
        return components
    }
}

/// Extends `MIME.CharacterSet` to conform to different encoding types.
extension MIME.CharacterSet {
    /// Provides the `String.Encoding` corresponding to the MIME character set.
    var encoding: String.Encoding? {
        switch self {
        case .ascii: .ascii
        case .iso8859: .isoLatin1
        case .utf8: .utf8
        default: nil
        }
    }
}

/// Extends `String` to allow decoding from additional MIME types.
extension String {
    /// Initializes a new `String` by decoding data using the specified transfer encoding and character encoding.
    ///
    /// The initializer attempts to decode the input `data` according to the provided `transferEncoding`.
    /// If the decoding succeeds, it returns the decoded string.
    /// Otherwise, it throws an error indicating failure.
    ///
    /// - Parameters:
    ///   - transferEncoding: The transfer encoding used on the data (e.g., base64, quoted-printable).
    ///   - data: The encoded data to decode.
    ///   - encoding: The character encoding to use for decoding the data into a string.
    /// - Throws: An error if the data cannot be decoded using the provided encoding schemes.
    /// - Returns: A decoded string constructed from the data.
    init(_ transferEncoding: ContentTransferEncoding?, data: Data, encoding: Encoding = .utf8) throws {
        switch transferEncoding {
        case .base64:
            do {
                try self.init(base64: data, encoding: encoding)  // Try strict decode first
            } catch {
                try self.init(nil, data: data, encoding: encoding)  // Try fuzzy (default) decode
            }
        case .quotedPrintable:
            do {
                try self.init(quotedPrintable: data, encoding: encoding)  // Try strict decode first
            } catch {
                try self.init(nil, data: data, encoding: encoding)  // Try fuzzy (default) decode
            }
        default:  // ASCII and unknown content transfer encodings
            guard let string: Self = Self(data: data, encoding: encoding) else {
                throw MIMEError.dataNotDecoded(data, encoding: encoding)
            }
            self = string
        }
    }
}

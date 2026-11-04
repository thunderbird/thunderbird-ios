// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MIME

/// A representation of an email attachment including disposition, ID, type, and data.
///
/// Provides convenience links for CID and content-disposition derived URLs.
public struct EmailAttachment: Sendable {
    public typealias ContentDisposition = MIME.ContentDisposition
    public typealias ContentID = MIME.ContentID

    public let contentDisposition: ContentDisposition
    public let contentID: ContentID?
    public let contentType: ContentType
    public let data: Data

    /// Creates an email attachment.
    ///
    /// - Parameters:
    ///   - data: The raw attachment data.
    ///   - contentType: The MIME content type of the attachment.
    ///   - contentDisposition: The content disposition; defaults to `.attachment`.
    ///   - contentID: An optional content ID for inline references.
    public init(
        data: Data,
        contentType: ContentType,
        contentDisposition: ContentDisposition? = nil,
        contentID: ContentID? = nil
    ) {
        self.contentDisposition = contentDisposition ?? .attachment
        self.contentID = contentID
        self.contentType = contentType
        self.data = data
    }

    /// Convenience links derived from the content ID and disposition.
    ///
    /// - Returns: An array of string URLs including CID and disposition URLs when available.
    var links: [String] {
        var links: [String] = []
        if let contentID {
            links.append(contentID.description)
            if let url: URL = try? URL(contentID: contentID) {
                links.append(url.absoluteString)
            }
        }
        if let url: URL = try? URL(contentDisposition: contentDisposition) {
            links.append(url.absoluteString)
        }
        return links
    }
}

/// Content-transfer decoding helpers.
extension Data {
    /// Decodes data using the provided content-transfer encoding.
    ///
    /// - Parameter contentTransferEncoding: The encoding used for transport.
    /// - Returns: The decoded data.
    /// - Throws: `MIMEError.dataNotDecoded` if decoding fails.
    func decoded(from contentTransferEncoding: MIME.ContentTransferEncoding?) throws -> Self {
        switch contentTransferEncoding {
        case .base64:
            guard let data: Self = Self(base64Encoded: self, options: .ignoreUnknownCharacters) else {
                throw MIMEError.dataNotDecoded(self)
            }
            return data
        default:
            return self
        }
    }
}

/// Convenience URL initializers for attachments.
extension URL {
    /// Creates a data URL for the given attachment using base64 encoding.
    ///
    /// - Parameter attachment: The attachment to represent as a URL.
    init(attachment: EmailAttachment) {
        self.init(string: "data:\(attachment.contentType);base64,\(attachment.data.base64EncodedString())")!
    }
}

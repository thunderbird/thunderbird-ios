// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension URL {

    /// Use ``MessageID`` with optional part ``ContentID`` as URI with `mid:` scheme
    /// Described in [RFC 2392](https://www.rfc-editor.org/info/rfc2392)
    public init(messageID: MessageID, contentID: ContentID? = nil) throws {
        guard let messageID: String = messageID.description.ascii,
            var url: Self = Self(string: "mid:\(messageID.unwrapping("<", ">"))")
        else {
            throw MIMEError.headerValueNotASCII
        }
        if let contentID: String = contentID?.description.ascii {
            url = url.appending(path: contentID.unwrapping("<", ">"))
        }
        self = url
    }

    /// Use ``ContentID`` as URI with `cid:` scheme
    /// Described in [RFC 2392](https://www.rfc-editor.org/info/rfc2392)
    public init(contentID: ContentID) throws {
        guard let contentID: String = contentID.description.ascii,
            let url: Self = Self(string: "cid:\(contentID.unwrapping("<", ">"))")
        else {
            throw MIMEError.headerValueNotASCII
        }
        self = url
    }

    /// Use ``ContentDisposition`` filename as URI
    public init(contentDisposition: ContentDisposition) throws {
        guard let filename: String = contentDisposition.file?.filename,
            !filename.isEmpty,
            let url: Self = Self(string: filename)
        else {
            throw URLError(.fileDoesNotExist)
        }
        self = url
    }
}

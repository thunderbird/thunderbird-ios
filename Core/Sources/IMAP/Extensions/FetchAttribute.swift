// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOIMAPCore

public typealias FetchAttribute = NIOIMAPCore.FetchAttribute

extension [FetchAttribute] {

    /// Fetch complete, raw message data in one blob.
    public static let complete: Self =
        [
            .bodySection(peek: true, .complete, nil)
        ] + standard

    /// Fetch all message headers and body structure map.
    public static let header: Self =
        [
            .bodySection(peek: true, .header, nil),
            .bodyStructure(extensions: true)
        ] + standard

    /// Fetch message envelope, IDs, flags and Gmail labels.
    public static let standard: Self = [
        .emailID,
        .envelope,
        .flags,
        .gmailLabels,
        .gmailMessageID,
        .gmailThreadID,
        .internalDate,
        .preview(lazy: true),
        .threadID,
        .uid
    ]

    // Filter unsupported attributes according to server capabilities
    func filtered(_ capabilities: Set<Capability>) -> Self {
        filter { attribute in
            switch attribute {
            case .emailID, .threadID: capabilities.contains(.objectID)
            case .gmailLabels, .gmailMessageID, .gmailThreadID: capabilities.contains(.gmailExtensions)
            case .preview: capabilities.contains(.preview)
            default: true
            }
        }
    }
}

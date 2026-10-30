// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore
import NIOIMAP

// Fetch messages by UID
struct UIDFetchCommand: IMAPCommand {
    let identifiers: UIDSetNonEmpty
    let attributes: [FetchAttribute]

    init(_ identifiers: UIDSetNonEmpty, attributes: [FetchAttribute]) {
        self.identifiers = identifiers
        self.attributes = attributes
    }

    // MARK: IMAPCommand
    typealias Result = [SequenceNumber: Message]
    typealias Handler = FetchHandler

    var name: String { "fetch" }

    func tagged(_ tag: String) -> NIOIMAPCore.TaggedCommand {
        TaggedCommand(tag: tag, command: .uidFetch(.set(identifiers), attributes, []))
    }
}

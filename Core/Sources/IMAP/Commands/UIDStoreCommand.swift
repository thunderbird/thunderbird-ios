// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore
import NIOIMAP

// Set message flags and Gmail labels by UID
struct UIDStoreCommand: IMAPCommand {
    let identifiers: UIDSetNonEmpty
    let data: StoreData

    init(_ identifiers: UIDSetNonEmpty, data: StoreData) {
        self.identifiers = identifiers
        self.data = data
    }

    // MARK: IMAPCommand
    typealias Result = Void
    typealias Handler = VoidResultHandler

    var name: String { "store" }

    func tagged(_ tag: String) -> NIOIMAPCore.TaggedCommand {
        TaggedCommand(tag: tag, command: .uidStore(.set(identifiers), [], data))
    }
}

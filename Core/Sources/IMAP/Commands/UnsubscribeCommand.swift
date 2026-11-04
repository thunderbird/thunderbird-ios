// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore
import NIOIMAP

// Unsubscribe from an existing mailbox
struct UnsubscribeCommand: IMAPCommand {
    let mailboxName: MailboxName

    init(_ mailboxName: MailboxName) {
        self.mailboxName = mailboxName
    }

    // MARK: IMAPCommand
    typealias Result = Void
    typealias Handler = VoidResultHandler

    var name: String { "unsubscribe \"\(mailboxName)\"" }

    func tagged(_ tag: String) -> NIOIMAPCore.TaggedCommand {
        TaggedCommand(tag: tag, command: .unsubscribe(mailboxName))
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore
import NIOIMAP

// Rename an existing mailbox
struct RenameCommand: IMAPCommand {
    let mailboxName: MailboxName
    let targetName: MailboxName

    init(_ mailboxName: MailboxName, to targetName: MailboxName) {
        self.mailboxName = mailboxName
        self.targetName = targetName
    }

    // MARK: IMAPCommand
    typealias Result = Void
    typealias Handler = VoidResultHandler

    var name: String { "rename \"\(mailboxName)\" to \"\(targetName)\"" }

    func tagged(_ tag: String) -> NIOIMAPCore.TaggedCommand {
        TaggedCommand(tag: tag, command: .rename(from: mailboxName, to: targetName, parameters: [:]))
    }
}

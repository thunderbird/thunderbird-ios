// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOIMAP

// Select current working mailbox in read-only mode
struct ExamineCommand: IMAPCommand {
    let mailboxName: MailboxName

    init(_ mailboxName: MailboxName) {
        self.mailboxName = mailboxName
    }

    // MARK: IMAPCommand
    typealias Result = MailboxStatus
    typealias Handler = ExamineHandler

    var name: String { "examine \"\(mailboxName)\"" }

    func tagged(_ tag: String) -> NIOIMAPCore.TaggedCommand {
        TaggedCommand(tag: tag, command: .examine(mailboxName))
    }
}

typealias ExamineHandler = SelectHandler

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore
import NIOIMAP

// Create new mailbox
struct CreateCommand: IMAPCommand {
    let mailboxName: MailboxName
    let parameters: [CreateParameter]

    init(_ mailboxName: MailboxName, parameters: [CreateParameter] = []) {
        self.mailboxName = mailboxName
        self.parameters = parameters
    }

    // MARK: IMAPCommand
    typealias Result = Void
    typealias Handler = VoidResultHandler

    var name: String { "create \"\(mailboxName)\"" }

    func tagged(_ tag: String) -> NIOIMAPCore.TaggedCommand {
        TaggedCommand(tag: tag, command: .create(mailboxName, parameters))
    }
}

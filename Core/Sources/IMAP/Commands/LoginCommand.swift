// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore
import NIOIMAP

// Log in to IMAP server with user/password combination
struct LoginCommand: IMAPCommand {
    let username: String
    let password: String

    // MARK: IMAPCommand
    typealias Result = [Capability]
    typealias Handler = CapabilityHandler

    var name: String { "login \"\(username)\"" }

    func tagged(_ tag: String) -> NIOIMAPCore.TaggedCommand {
        TaggedCommand(tag: tag, command: .login(username: username, password: password))
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore
import NIOIMAP

struct AuthenticateCommand: IMAPCommand {
    let authentication: Authentication

    init(_ authentication: Authentication) {
        self.authentication = authentication
    }

    // MARK: IMAPCommand
    typealias Result = [Capability]
    typealias Handler = CapabilityHandler

    var name: String { "authenticate \"\(authentication.user)\"" }

    func tagged(_ tag: String) -> NIOIMAPCore.TaggedCommand {
        TaggedCommand(
            tag: tag,
            command:
                .authenticate(
                    mechanism: authentication.mechanism,
                    initialResponse: try? authentication.initialResponse
                )
        )
    }
}

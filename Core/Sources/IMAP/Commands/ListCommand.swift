// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore
import NIOIMAP

// List all mailboxes available for authenticated user
struct ListCommand: IMAPCommand {
    let options: [ReturnOption]
    let wildcard: Character

    init(
        options: [ReturnOption] = [
            .subscribed,
            .statusOption([
                .messageCount,
                .recentCount,
                .unseenCount
            ])
        ],
        wildcard: Character
    ) {
        self.options = options
        self.wildcard = wildcard
    }

    // MARK: IMAPCommand
    typealias Result = [(MailboxInfo, MailboxStatus?)]
    typealias Handler = ListHandler

    var name: String { "list" }

    func tagged(_ tag: String) -> NIOIMAPCore.TaggedCommand {
        TaggedCommand(tag: tag, command: .list(nil, reference: .reference, .mailbox(wildcard), options))
    }
}

class ListHandler: IMAPCommandHandler, @unchecked Sendable {

    // MARK: IMAPCommandHandler
    typealias InboundIn = Response
    typealias InboundOut = Response
    typealias Result = [(MailboxInfo, MailboxStatus?)]

    var mailboxes: [MailboxInfo] = []
    var status: [MailboxName: MailboxStatus] = [:]
    var clientBug: String? = nil
    let promise: EventLoopPromise<Result>
    let tag: String

    required init(tag: String, promise: EventLoopPromise<Result>) {
        self.promise = promise
        self.tag = tag
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let response: Response = unwrapInboundIn(data)
        clientBug = response.clientBug
        switch response {
        case .tagged(let taggedResponse):
            switch taggedResponse.state {
            case .bad(let text), .no(let text):
                promise.fail(IMAPError.commandFailed(text.text))
            case .ok:
                promise.succeed(mailboxes.map { ($0, status[$0.path.name]) })
            }
        case .untagged(let payload):
            switch payload {
            case .mailboxData(.list(let mailbox)):
                mailboxes.append(mailbox)
            case .mailboxData(.status(let name, let status)):
                self.status[name] = status
            default:
                break
            }
        default:
            break
        }
        context.fireChannelRead(data)
    }
}

extension MailboxName {
    static var reference: Self { Self(ByteBuffer(string: "")) }
}

extension MailboxPatterns {
    static func mailbox(_ wildcard: Character = .wildcard) -> Self {
        .mailbox(ByteBuffer(string: "\(wildcard)"))
    }
}

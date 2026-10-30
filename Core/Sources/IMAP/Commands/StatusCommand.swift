// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore
import NIOIMAP

// Fetch status (message counts) for given mailbox
struct StatusCommand: IMAPCommand {
    let mailboxName: MailboxName
    let attributes: [MailboxAttribute]

    init(_ mailboxName: MailboxName, attributes: [MailboxAttribute] = .standard) {
        self.mailboxName = mailboxName
        self.attributes = attributes
    }

    // MARK: IMAPCommand
    typealias Result = MailboxStatus
    typealias Handler = StatusHandler

    var name: String { "status \"\(mailboxName)\"" }

    func tagged(_ tag: String) -> NIOIMAPCore.TaggedCommand {
        TaggedCommand(tag: tag, command: .status(mailboxName, attributes))
    }
}

class StatusHandler: IMAPCommandHandler, @unchecked Sendable {
    private(set) var status: MailboxStatus = MailboxStatus()

    // MARK: IMAPCommandHandler
    typealias InboundIn = Response
    typealias InboundOut = Response
    typealias Result = MailboxStatus

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
                promise.succeed(status)
            }
        case .untagged(let payload):
            switch payload {
            case .mailboxData(.status(_, let status)):
                self.status = status
            default:
                break
            }
        default:
            break
        }
        context.fireChannelRead(data)
    }
}

extension [MailboxAttribute] {
    static func extended(_ capabilities: Set<Capability>) -> Self {
        Array(Set(capabilities.flatMap { extended($0) }))
    }

    static func extended(_ capability: Capability) -> Self {
        switch capability {
        case .objectID: [.mailboxID]
        case .uidPlus: [.uidNext, .uidValidity]
        case .mailboxSpecificAppendLimit: [.appendLimit]
        case .condStore: [.highestModificationSequence]
        case .status(.size): [.size]
        default: []
        }
    }

    static var standard: Self {
        [
            .messageCount,
            .recentCount,
            .unseenCount
        ]
    }
}

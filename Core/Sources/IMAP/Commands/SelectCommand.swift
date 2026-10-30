// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore
import NIOIMAP

// Select current working mailbox in read/write mode
struct SelectCommand: IMAPCommand {
    let mailboxName: MailboxName

    init(_ mailboxName: MailboxName) {
        self.mailboxName = mailboxName
    }

    // MARK: IMAPCommand
    typealias Result = MailboxStatus
    typealias Handler = SelectHandler

    var name: String { "select \"\(mailboxName)\"" }

    func tagged(_ tag: String) -> NIOIMAPCore.TaggedCommand {
        TaggedCommand(tag: tag, command: .select(mailboxName))
    }
}

class SelectHandler: IMAPCommandHandler, @unchecked Sendable {

    // MARK: IMAPCommandHandler
    typealias InboundIn = Response
    typealias InboundOut = Response
    typealias Result = MailboxStatus

    var status: MailboxStatus = MailboxStatus()
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
            // Aggregate any `MailboxStatus` elements returned in mail server response
            switch payload {
            case .conditionalState(let status):
                switch status {
                case .ok(let responseText):
                    switch responseText.code {
                    case .uidNext(let uid):
                        self.status.nextUID = uid
                    case .uidValidity(let uid):
                        self.status.uidValidity = uid
                    case .unseen(let count):
                        self.status.unseenCount = Int(count.rawValue)
                    default:
                        break
                    }
                default:
                    break
                }
            case .mailboxData(let data):
                switch data {
                case .exists(let count):
                    status.messageCount = count
                case .recent(let count):
                    status.recentCount = count
                default:
                    break
                }
                break
            default:
                break
            }
        default:
            break
        }
        context.fireChannelRead(data)
    }
}

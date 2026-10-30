// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore
import NIOIMAP

// Long-running handler streams pushed idle events
class IdleHandler: IMAPCommandHandler, @unchecked Sendable {
    typealias Continuation = AsyncStream<IdleEvent>.Continuation
    private(set) var continuation: Continuation? = nil

    convenience init(tag: String, promise: EventLoopPromise<Void>, continuation: Continuation?) {
        self.init(tag: tag, promise: promise)
        self.continuation = continuation
    }

    private var components: [Message.Component] = []
    private var sequenceNumber: SequenceNumber?

    // MARK: IMAPCommandHandler
    typealias InboundIn = Response
    typealias InboundOut = Response
    typealias Result = Void

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
            // Always finish continuation first, then fulfill promise
            continuation?.finish()
            switch taggedResponse.state {
            case .bad(let text), .no(let text):
                promise.fail(IMAPError.commandFailed(text.text))
            case .ok:
                promise.succeed()
            }
        case .untagged(let payload):
            switch payload {
            case .conditionalState(let status):
                switch status {
                case .bye(let text):
                    continuation?.yield(.bye(text.text))
                    continuation?.finish()
                    promise.succeed()
                default:
                    break
                }
            case .mailboxData(let data):
                switch data {
                case .exists(let count):
                    continuation?.yield(.status(MailboxStatus(messageCount: count)))
                case .recent(let count):
                    continuation?.yield(.status(MailboxStatus(recentCount: count)))
                default:
                    break
                }
            case .messageData(let data):
                switch data {
                case .expunge(let sequenceNumber):
                    continuation?.yield(.expunge(sequenceNumber))
                default:
                    break
                }
            default:
                break
            }
        case .fetch(let response):
            switch response {
            case .start(let sequenceNumber):
                self.sequenceNumber = sequenceNumber
                components = []
            case .simpleAttribute(let attribute):
                guard let component: Message.Component = Message.Component(attribute) else { break }
                components.append(component)
            case .finish:
                guard let sequenceNumber, !components.isEmpty else { break }
                continuation?.yield(.fetch(sequenceNumber, components))
                self.sequenceNumber = nil
                components = []
            default:
                break
            }
        case .fatal(let text):
            continuation?.yield(.bye(text.text))
            continuation?.finish()
            promise.succeed()
        default:
            break
        }
        context.fireChannelRead(data)
    }
}

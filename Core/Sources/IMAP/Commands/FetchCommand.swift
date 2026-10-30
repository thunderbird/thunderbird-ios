// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import NIOCore
import NIOIMAPCore

// Fetch messages by mailbox sequence number
struct FetchCommand: IMAPCommand {
    let identifiers: MessageIdentifierSetNonEmpty<SequenceNumber>
    let attributes: [FetchAttribute]

    init(_ identifiers: MessageIdentifierSetNonEmpty<SequenceNumber>, attributes: [FetchAttribute]) {
        self.identifiers = identifiers
        self.attributes = attributes
    }

    // MARK: IMAPCommand
    typealias Result = [SequenceNumber: Message]
    typealias Handler = FetchHandler

    var name: String { "fetch" }

    func tagged(_ tag: String) -> NIOIMAPCore.TaggedCommand {
        TaggedCommand(tag: tag, command: .fetch(.set(identifiers), attributes, []))
    }
}

class FetchHandler: IMAPCommandHandler, @unchecked Sendable {
    var messages: Result = [:]
    var isStreaming: Bool { streaming != nil }

    private var streaming: (kind: StreamingKind, data: Data, byteCount: Int)?
    private var sequenceNumber: SequenceNumber?
    private var components: [Message.Component] = []

    // MARK: IMAPCommandHandler
    typealias InboundIn = Response
    typealias InboundOut = Response
    typealias Result = [SequenceNumber: Message]

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
                promise.succeed(messages)
            }
        case .fetch(let response):
            switch response {
            case .start(let sequenceNumber):
                self.sequenceNumber = sequenceNumber
            case .simpleAttribute(let attribute):
                guard let component: Message.Component = Message.Component(attribute) else { break }
                components.append(component)
            case .streamingBegin(let kind, let byteCount):
                streaming = (kind, Data(), byteCount)
            case .streamingBytes(let bytes):
                streaming?.data.append(Data(bytes.readableBytesView))
            case .streamingEnd:
                if let streaming {
                    switch streaming.kind {
                    case .body(let section, _):
                        guard streaming.data.count == streaming.byteCount else { break }
                        components.append(.bodyPart(section, streaming.data))
                    default:
                        break
                    }
                }
                streaming = nil
            case .finish:
                if let sequenceNumber {
                    messages[sequenceNumber] = Message(components)
                }
                sequenceNumber = nil
                components = []
            default:
                break
            }
        default:
            break
        }
        context.fireChannelRead(data)
    }

}

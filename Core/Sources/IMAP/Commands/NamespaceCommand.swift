// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore
import NIOIMAP

// Fetch namespaces available to authenticated user
struct NamespaceCommand: IMAPCommand {

    // MARK: IMAPCommand
    typealias Result = [Namespace]
    typealias Handler = NamespaceHandler

    var name: String { "namespace" }

    func tagged(_ tag: String) -> NIOIMAPCore.TaggedCommand {
        TaggedCommand(tag: tag, command: .namespace)
    }
}

class NamespaceHandler: IMAPCommandHandler, @unchecked Sendable {

    // MARK: IMAPCommandHandler
    typealias InboundIn = Response
    typealias InboundOut = Response
    typealias Result = [Namespace]

    var namespaces: [Namespace] = []
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
                promise.succeed(namespaces)
            }
        case .untagged(let payload):
            switch payload {
            case .mailboxData(.namespace(let response)):
                // Map scoped NIO namespace descriptions into single, filterable collection
                for description in response.userNamespace {
                    namespaces.append(Namespace(.user, description: description))
                }
                for description in response.sharedNamespace {
                    namespaces.append(Namespace(.shared, description: description))
                }
                for description in response.otherUserNamespace {
                    namespaces.append(Namespace(.other, description: description))
                }
            default:
                break
            }
        default:
            break
        }
        context.fireChannelRead(data)
    }
}

private extension Namespace {
    init(_ scope: Scope, description: NamespaceDescription) {
        self.init(scope, delimiter: description.delimiter, prefix: description.prefix)
    }
}

private extension NamespaceDescription {
    var prefix: String { String(decoding: string.readableBytesView, as: UTF8.self) }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MIME
import NIOCore
import NIOIMAP

// Bundle NIO IMAP commands with a corresponding result type and handler
protocol IMAPCommand: CustomStringConvertible, Equatable where Result: Sendable {
    associatedtype Result
    associatedtype Handler: IMAPCommandHandler where Handler.Result == Result
    var name: String { get }
    var timeout: Int64 { get }  // Seconds
    func tagged(_ tag: String) -> TaggedCommand  // NIOIMAP command
}

extension IMAPCommand {

    // MARK: IMAPCommand
    var timeout: Int64 { .timeout }
    var description: String { "\(name) command" }
}

// Command-specific handler; process and deliver result via NIO promise
protocol IMAPCommandHandler: ChannelInboundHandler, RemovableChannelHandler, Sendable where Result: Sendable {
    associatedtype Result
    init(tag: String, promise: EventLoopPromise<Result>)
    var promise: EventLoopPromise<Result> { get }
    var tag: String { get }
    var clientBug: String? { get set }
}

extension IMAPCommandHandler {

    // MARK: IMAPCommandHandler
    func errorCaught(context: ChannelHandlerContext, error: any Error) {
        promise.fail(error)
        context.pipeline.removeHandler(self, promise: nil)
        context.fireErrorCaught(error)
    }
}

// Default succeed/fail handler implementation for void-result commands
extension IMAPCommandHandler where InboundIn == Response, Result == Void {

    // MARK: IMAPCommandHandler
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let response: Response = unwrapInboundIn(data)
        clientBug = response.clientBug
        switch response {
        case .tagged(let taggedResponse):
            switch taggedResponse.state {
            case .bad(let text), .no(let text):
                promise.fail(IMAPError.unexpectedResponse(text))
            case .ok:
                promise.succeed(())
            }
        case .untagged(let payload):
            switch payload {
            case .conditionalState(let status):
                switch status {
                case .bad(let text), .no(let text):
                    promise.fail(IMAPError.unexpectedResponse(text))
                default:
                    promise.succeed()
                }
            default:
                promise.fail(IMAPError.unexpectedResponse(response.debugDescription))
            }
        default:
            promise.fail(IMAPError.unexpectedResponse(response.debugDescription))
        }
        context.pipeline.removeHandler(self, promise: nil)
        context.fireChannelRead(data)
    }
}

extension Int64 {
    static let timeout: Self = 60  // Practical default
}

// IMAP [CLIENTBUG] is an error code mail servers include in responses to
// indicate that a client-sent command was understood, but malformed somehow,
// anything from byte order to, typically, whitespace formatting.
//
// Most IMAP client implementations (including NIOIMAP, used here to wire-encode
// commands) just format commands one way that empirically works everywhere, and
// ignore [CLIENTBUG] warnings completely.
//
// Only manually retrieving [CLIENTBUG] warnings here for debug logging, because
// I'm new to IMAP, and I'm not sure what's important and not yet.
//
// TODO: Delete once NIOIMAP handling of [CLIENTBUG] benchmarked and confirmed
extension Response {
    var clientBug: String? {
        switch self {
        case .tagged(let response):
            guard response.state.responseText.code == .clientBug else { fallthrough }
            return response.state.responseText.text
        default:
            return nil
        }
    }
}

extension TaggedResponse.State {
    var responseText: ResponseText {
        switch self {
        case .bad(let responseText), .no(let responseText), .ok(let responseText): responseText
        }
    }
}

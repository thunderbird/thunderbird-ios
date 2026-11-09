// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore

// Proxy `ByteToMessageHandler` as `@unchecked Sendable`
final class MessageHandler<Decoder: ByteToMessageDecoder>: ChannelInboundHandler, @unchecked Sendable {
    init(_ decoder: Decoder) {
        handler = ByteToMessageHandler(decoder)
    }

    private let handler: ByteToMessageHandler<Decoder>

    // MARK: ChannelInboundHandler
    typealias InboundIn = ByteBuffer
    typealias InboundOut = Decoder.InboundOut

    func handlerAdded(context: ChannelHandlerContext) {
        handler.handlerAdded(context: context)
    }

    func handlerRemoved(context: ChannelHandlerContext) {
        handler.handlerRemoved(context: context)
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        handler.channelRead(context: context, data: data)
    }

    func channelInactive(context: ChannelHandlerContext) {
        handler.channelInactive(context: context)
    }

    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        handler.userInboundEventTriggered(context: context, event: event)
    }
}

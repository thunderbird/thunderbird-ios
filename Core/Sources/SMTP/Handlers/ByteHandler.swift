// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore

/// An outbound handler that turns messages into bytes with an encoder, by forwarding each call to NIO's
/// `MessageToByteHandler`.
///
/// It exists so the pipeline can hold the handler as `Sendable`, which NIO's handler isn't.
// Proxy `MessageToByteHandler` as `@unchecked Sendable`
final class ByteHandler<Encoder: MessageToByteEncoder>: ChannelOutboundHandler, @unchecked Sendable {
    /// - Parameter encoder: The encoder that writes each outbound message as bytes.
    init(_ encoder: Encoder) {
        handler = MessageToByteHandler(encoder)
    }

    private let handler: MessageToByteHandler<Encoder>

    // MARK: ChannelOutboundHandler
    typealias OutboundOut = ByteBuffer
    typealias OutboundIn = Encoder.OutboundIn

    func handlerAdded(context: ChannelHandlerContext) {
        handler.handlerAdded(context: context)
    }

    func handlerRemoved(context: ChannelHandlerContext) {
        handler.handlerRemoved(context: context)
    }

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        handler.write(context: context, data: data, promise: promise)
    }

    func flush(context: ChannelHandlerContext) {
        handler.flush(context: context)
    }
}

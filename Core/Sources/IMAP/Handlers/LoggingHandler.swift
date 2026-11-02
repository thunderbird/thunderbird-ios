// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore
import OSLog

// Generic NIO channel logger, a pass-through duplex handler
// Reads the raw bytes going both directions without modifying
// Logs only when built with DEBUG
final class LoggingHandler: ChannelDuplexHandler, @unchecked Sendable {
    let logger: Logger?

    init(_ logger: Logger? = nil) {
        self.logger = logger
    }

    // MARK: ChannelDuplexHandler
    typealias InboundIn = ByteBuffer
    typealias OutboundIn = ByteBuffer

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        #if DEBUG
        logger?.debug("\(self.unwrapOutboundIn(data).readableBytesView)")
        #endif
        context.write(data, promise: promise)  // Handler only observes; pass unmodified data to next handler
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        #if DEBUG
        logger?.debug("\(self.unwrapInboundIn(data).readableBytesView)")
        #endif
        context.fireChannelRead(data)  // Pass unmodified data to next handler
    }
}

extension ByteBufferView: @retroactive CustomStringConvertible {

    // MARK: CustomStringConvertible
    public var description: String { String(decoding: self, as: UTF8.self) }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore
import OSLog

/// A pass-through handler that logs the raw bytes sent and received, in debug builds only.
///
/// - Important: ``SMTPClient`` never gives it a logger, so it currently logs nothing. With a logger, the debug log
///   would include the base64 `AUTH LOGIN` user name and password, which anyone can decode, and the whole email.
// TODO: Leave the `AUTH LOGIN` lines out of the log if this handler is given a logger.
// Generic NIO channel logger, a pass-through duplex handler
// Reads the raw bytes going both directions without modifying
// Logs only when built with DEBUG
final class LoggingHandler: ChannelDuplexHandler, @unchecked Sendable {
    /// Where to log. `nil` logs nothing.
    let logger: Logger?

    /// - Parameter logger: Where to log. Defaults to `nil`, which logs nothing.
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

/// Extends `ByteBufferView` with its bytes as UTF-8 text, for logging.
///
/// - Important: The IMAP module declares the same public conformance in its own `LoggingHandler.swift`. When both
///   modules are loaded, Swift doesn't define which of the two is used.
// TODO: Declare this conformance in one shared place, not in both SMTP and IMAP.
extension ByteBufferView: @retroactive CustomStringConvertible {

    // MARK: CustomStringConvertible
    public var description: String { String(decoding: self, as: UTF8.self) }
}

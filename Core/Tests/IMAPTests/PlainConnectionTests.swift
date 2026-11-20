// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import IMAP
import NIOCore
import NIOPosix
import Testing

struct PlainConnectionTests {
    //Expect: Connect and read the server capabilities without a TLS handshake.
    //Case: When the server speaks plain-text IMAP and connection security is none.
    @Test func connect_readsCapabilities_whenConnectionSecurityIsNone() async throws {
        // Arrange
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let listener: Channel = try await PlainIMAPServer.listen(on: group)
        let input = Server(.none, hostname: "127.0.0.1", port: listener.localAddress!.port!)
        let expected: Bool = true
        let client = IMAPClient(input, logger: nil)

        // Act
        try? await client.connect()
        let actual: Bool = client.capabilities.contains(.idle)

        // Assert
        #expect(actual == expected)

        try? client.disconnect()
        try await listener.close()
        try await group.shutdownGracefully()
    }
}

/// Minimal plain-text IMAP server: greets, answers `CAPABILITY`, and hangs up on anything else (like a TLS handshake).
private final class PlainIMAPServer: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    static func listen(on group: EventLoopGroup) async throws -> Channel {
        try await ServerBootstrap(group: group)
            .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.eventLoop.makeCompletedFuture {
                    try channel.pipeline.syncOperations.addHandler(PlainIMAPServer())
                }
            }
            .bind(host: "127.0.0.1", port: 0)
            .get()
    }

    func channelActive(context: ChannelHandlerContext) {
        write("* OK ready\r\n", context: context)
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer: ByteBuffer = unwrapInboundIn(data)
        received += buffer.readString(length: buffer.readableBytes) ?? ""
        while let range = received.range(of: "\r\n") {
            let line: String = String(received[..<range.lowerBound])
            received.removeSubrange(..<range.upperBound)
            let words: [Substring] = line.split(separator: " ")
            guard words.count == 2, words[1].uppercased() == "CAPABILITY" else {
                context.close(promise: nil)
                return
            }
            write("* CAPABILITY IMAP4rev1 IDLE\r\n\(words[0]) OK CAPABILITY completed\r\n", context: context)
        }
        if received.utf8.count > 1024 {  // Never saw a line ending: not IMAP
            context.close(promise: nil)
        }
    }

    private var received: String = ""

    private func write(_ string: String, context: ChannelHandlerContext) {
        context.writeAndFlush(wrapOutboundOut(context.channel.allocator.buffer(string: string)), promise: nil)
    }
}

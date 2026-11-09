// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import Network
import NIOCore
import NIOExtras
import NIOSSL
import NIOTransportServices
import OSLog

/// Configure `SMTPClient` with a single ``Server`` and send ``Email``.
public struct SMTPClient {
    public let server: Server

    public init(
        _ server: Server,
        logger: Logger? = Logger(subsystem: "net.thunderbird", category: "SMTP")
    ) {
        group = NIOTSEventLoopGroup(loopCount: 1, defaultQoS: .utility)
        self.server = server
        self.logger = logger
    }

    public func send(_ email: [Email]) async throws {
        for email in email {
            try await send(email)
        }
    }

    public func send(_ email: Email) async throws {
        guard !email.allRecipients.isEmpty else {
            throw SMTPError.emailRecipientNotFound  // Nothing would be sent
        }
        for recipient in email.allRecipients {
            try await send(email, to: recipient)
        }
    }

    func send(_ email: Email, to recipient: EmailAddress) async throws {
        do {
            let done: EventLoopPromise<Void> = group.next().makePromise()
            let bootstrap: NIOClientTCPBootstrap = try .bootstrap(
                email: email,
                recipient: recipient,
                server: server,
                group: group,
                done: done
            )
            let logger: Logger? = logger
            logger?.info("Connecting to \(server)…")
            let connection: EventLoopFuture<any Channel> = bootstrap.connect(host: server.hostname, port: server.port)
            connection.cascadeFailure(to: done)
            logger?.info("Sending…")
            try await withCheckedThrowingContinuation { continuation in
                done.futureResult.map {
                    logger?.info("Sent")
                    connection.whenSuccess { $0.close(promise: nil) }
                    continuation.resume()
                }.whenFailure { error in
                    logger?.error("Send failed: \(error.localizedDescription)")
                    connection.whenSuccess { $0.close(promise: nil) }
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            throw SMTPError(error)
        }
    }

    private let group: EventLoopGroup
    private let logger: Logger?
}

private extension NIOClientTCPBootstrap {
    static func bootstrap(
        email: Email,
        recipient: EmailAddress,
        server: Server,
        logger: Logger? = nil,
        group: EventLoopGroup,
        done: EventLoopPromise<Void>
    ) throws -> Self {
        let bootstrap: Self
        switch server.connectionSecurity {
        case .startTLS:
            bootstrap = try Self(
                NIOTSConnectionBootstrap(group: group),
                tls: NIOSSLClientTLSProvider(context: .ssl, serverHostname: server.hostname)
            )
        case .tls:
            bootstrap = Self(
                NIOTSConnectionBootstrap(group: group),
                tls: NIOTSClientTLSProvider()
            )
            bootstrap.enableTLS()
        case .none:
            bootstrap = Self(
                NIOTSConnectionBootstrap(group: group),
                tls: NIOTSClientTLSProvider()
            )
        }
        return bootstrap.channelInitializer { channel in
            channel.pipeline.addHandlers(
                [
                    LoggingHandler(logger),
                    MessageHandler(LineBasedFrameDecoder()),
                    ResponseHandler(),
                    ByteHandler(RequestEncoder()),
                    SendHandler(email, recipient: recipient, server: server, done: done)
                ]
            )
        }
    }
}

private extension NIOSSLContext {
    static var ssl: Self { try! Self(configuration: .makeClientConfiguration()) }
}

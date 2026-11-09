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
///
/// Every recipient of an email gets their own connection and their own copy: connect, greet with `EHLO`, upgrade with
/// `STARTTLS` when the server uses it, sign in with `AUTH LOGIN`, then `MAIL FROM`, one `RCPT TO`, `DATA` and `QUIT`.
/// `SendHandler` runs those steps. The connections use a one-thread Network.framework event loop group that the
/// client creates.
///
/// ## Example
///
/// Send a plain text email through a STARTTLS server:
///
/// ```swift
/// let client = SMTPClient(
///     Server(.startTLS, hostname: "smtp.example.com", username: "me@example.com", password: "app-password")
/// )
/// let email = Email(
///     sender: "me@example.com",
///     recipients: ["you@example.com"],
///     subject: "Hello",
///     body: try Body(part: Part(data: "Hello".data(using: .ascii)!, contentType: .text(.plain, .ascii)))
/// )
/// try await client.send(email)  // One session per recipient; throws an SMTPError if one fails
/// ```
///
/// - Important: Nothing in the app sends mail with this client yet. The account connection test creates a client but
///   doesn't connect or send, so it reports success without checking the server.
// TODO: The event loop group is never shut down, so each client keeps its thread. Shut it down when the client is done.
public struct SMTPClient {
    /// The server mail is sent through.
    public let server: Server

    /// Make a client for a server.
    ///
    /// - Parameters:
    ///   - server: The server to send through, with its credentials.
    ///   - logger: Where connection progress and failures are logged. Defaults to the `net.thunderbird` subsystem and
    ///     `SMTP` category; `nil` turns logging off.
    public init(
        _ server: Server,
        logger: Logger? = Logger(subsystem: "net.thunderbird", category: "SMTP")
    ) {
        group = NIOTSEventLoopGroup(loopCount: 1, defaultQoS: .utility)
        self.server = server
        self.logger = logger
    }

    /// Send several emails, one after another.
    ///
    /// - Parameter email: The emails to send.
    /// - Throws: The first error. The emails after it aren't sent, and the ones before it have already been delivered.
    public func send(_ email: [Email]) async throws {
        for email in email {
            try await send(email)
        }
    }

    /// Send an email to everyone it's addressed to.
    ///
    /// Each recipient, whether To, Cc or Bcc, gets a separate connection and a separate copy, in that order.
    ///
    /// - Parameter email: The email to send.
    /// - Throws: An ``SMTPError`` from the first recipient that fails. Recipients before it already have the email.
    /// - Important: An email with no recipients returns without error and without sending anything.
    // TODO: Throw `SMTPError.emailRecipientNotFound` when there are no recipients, and send to all recipients in one
    // session (one `RCPT TO` each) so a failure doesn't leave the email delivered to only some of them.
    public func send(_ email: Email) async throws {
        for recipient in email.allRecipients {
            try await send(email, to: recipient)
        }
    }

    /// Send an email to one recipient over a new connection.
    ///
    /// - Parameters:
    ///   - email: The email to send.
    ///   - recipient: The address used in `RCPT TO`.
    /// - Throws: An ``SMTPError``. Errors that aren't SMTP errors, such as connection failures, become
    ///   ``SMTPError/response(_:)`` with their description.
    /// - Important: There's no timeout for the server's replies, so a server that stops responding leaves this
    ///   waiting forever.
    // TODO: Add a timeout for the whole session, and close the connection when it expires.
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

/// Extends `NIOClientTCPBootstrap` with the connection set-up for one SMTP send.
private extension NIOClientTCPBootstrap {
    /// Make a bootstrap whose channel runs one send: logging, line framing, reply parsing, command encoding and the
    /// ``SendHandler`` steps.
    ///
    /// STARTTLS servers start in plain text, with TLS added later by ``SendHandler``. SSL/TLS servers get
    /// Network.framework TLS from the start. Servers without security stay in plain text.
    ///
    /// - Parameters:
    ///   - email: The email to send.
    ///   - recipient: The one recipient for this connection.
    ///   - server: The server to connect to.
    ///   - logger: The logger for ``LoggingHandler``. `send(_:to:)` doesn't pass one, so it is always `nil`.
    ///   - group: The event loop group to connect on.
    ///   - done: Completed by ``SendHandler`` when the send succeeds or fails.
    /// - Throws: An error if the STARTTLS client provider can't be made.
    // TODO: Pass the client's logger through, or remove `LoggingHandler`; right now it never logs.
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

/// Extends `NIOSSLContext` with the client context used for STARTTLS.
private extension NIOSSLContext {
    /// A client TLS context with the default configuration, which verifies the server's certificate.
    static var ssl: Self { try! Self(configuration: .makeClientConfiguration()) }
}

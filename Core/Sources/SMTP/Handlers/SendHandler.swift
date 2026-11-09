// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import NIOCore
import NIOSSL

/// Runs one SMTP session for one email and one recipient, sending each command when the reply to the previous one
/// arrives.
///
/// The steps are: wait for the greeting, `EHLO`, then `STARTTLS` and adding a TLS handler if the server uses STARTTLS,
/// `AUTH LOGIN` with the user name and password, `MAIL FROM`, `RCPT TO`, `DATA`, the email, and `QUIT`. `done`
/// succeeds after the reply to `QUIT`, or fails with the first error.
///
/// - Important: Known problems:
///   - With ``ConnectionSecurity/tls`` (implicit TLS, usually port 465), the TLS comes from Network.framework, but
///     signing in waits for an `NIOSSLClientHandler` in the pipeline, which isn't there. So the send fails with
///     `ChannelPipelineError.notFound` right after `EHLO`, before signing in. (The Account module also refuses `.tls`
///     for SMTP.)
///   - Two `fatalError` calls crash the app on unexpected server behavior: a reply while the TLS handler is being
///     added, and a positive reply after an error was already recorded.
///   - Any 2xx or 3xx reply moves on to the next step; the code isn't checked against the one the step expects.
///   - With ``ConnectionSecurity/none``, the user name and password are sent unencrypted.
// TODO: Make implicit TLS work: don't require `NIOSSLClientHandler` when the connection's TLS comes from
// Network.framework.
// TODO: Fail `done` instead of calling `fatalError`, and check each reply code against the step.
final class SendHandler: ChannelInboundHandler, @unchecked Sendable {
    let email: Email
    /// The one recipient this session sends to.
    let recipient: EmailAddress
    /// The server, its security setting and the credentials.
    let server: Server

    /// Make a handler for one send.
    ///
    /// - Parameters:
    ///   - email: The email to send.
    ///   - recipient: The address for `RCPT TO`. If it's `nil`, the first To address is used.
    ///   - server: The server and credentials.
    ///   - done: Succeeds when the server accepts `QUIT`, or fails with the first error. If the recipient's address is
    ///     empty, it fails at once with ``SMTPError/emailRecipientNotFound``.
    init(_ email: Email, recipient: EmailAddress?, server: Server, done: EventLoopPromise<Void>) {
        self.email = email
        self.recipient = recipient ?? email.recipients.first ?? ""
        self.server = server
        self.done = done
        if self.recipient.value.isEmpty {
            expect = .error(SMTPError.emailRecipientNotFound)
        }
    }

    /// The reply the handler is waiting for, which decides the next command.
    private enum Expect {
        case initialMessageFromServer
        case okForHello
        case okForStartTLS
        case tlsHandlerToBeAdded
        case okForAuthBegin
        case okAfterUsername
        case okAfterPassword
        case okAfterMailFrom
        case okAfterRecipient
        case okAfterData
        case okAfterTransferData
        case okAfterQuit
        case error(Error)
        case nothing
    }

    private let done: EventLoopPromise<Void>
    private var context: ChannelHandlerContext?

    /// The current step. Setting it to `.error` fails `done`.
    private var expect: Expect = .initialMessageFromServer {
        didSet {
            guard case .error(let error) = expect else { return }
            done.fail(error)
        }
    }

    /// Write a command, and fail `done` if the write fails.
    private func send(context: ChannelHandlerContext, command: Request) {
        context.writeAndFlush(wrapOutboundOut(command)).cascadeFailure(to: done)
    }

    /// Start `AUTH LOGIN`, after checking for an `NIOSSLClientHandler` when the server uses STARTTLS or SSL/TLS.
    ///
    /// Uses and then clears the context saved in `context`. The check succeeds right away when it runs on the event
    /// loop, which it always does here.
    private func sendAuthLogin() {
        @Sendable func send() {
            guard let context else { return }
            self.send(context: context, command: .authLogin)
            expect = .okForAuthBegin
        }

        switch server.connectionSecurity {
        case .startTLS, .tls:
            if let context {
                context.channel.pipeline.handler(type: NIOSSLClientHandler.self).map { _ in
                    send()  // SSL handler present in pipeline
                }.whenFailure { error in
                    guard self.server.connectionSecurity == .tls else { return }
                    self.expect = .error(error)
                }
            } else {
                expect = .error(SMTPError.requiredTLSNotConfigured)
            }
        case .none:
            send()  // Authenticate in plain text
        }
        self.context = nil
    }

    // MARK: ChannelInboundHandler
    typealias OutboundIn = Email
    typealias OutboundOut = Request
    typealias InboundIn = Response

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        switch unwrapInboundIn(data) {
        case .error(let error):
            expect = .error(SMTPError.response(error))
        case .ok:
            switch expect {
            case .initialMessageFromServer:
                send(context: context, command: .hello(server.hostname))
                expect = .okForHello
            case .okForHello:
                switch server.connectionSecurity {
                case .startTLS:
                    send(context: context, command: .startTLS)
                    expect = .okForStartTLS
                case .tls, .none:
                    self.context = context
                    sendAuthLogin()
                }
            case .okForStartTLS:
                expect = .tlsHandlerToBeAdded
                self.context = context
                context.channel.eventLoop.makeCompletedFuture {
                    try context.channel.pipeline.syncOperations.addHandler(
                        try NIOSSLClientHandler(context: .ssl, serverHostname: server.hostname),
                        position: .first
                    )
                }.whenComplete { result in
                    switch self.expect {
                    case .tlsHandlerToBeAdded:
                        switch result {
                        case .failure(let error):
                            self.expect = .error(error)
                        case .success:
                            self.sendAuthLogin()
                        }
                        break
                    default:
                        self.expect = .error(SMTPError.requiredTLSNotConfigured)
                    }
                }
            case .tlsHandlerToBeAdded:
                fatalError("SMTP.SendHandler.channelRead(context:data:) before TLS handler added to pipeline")
            case .okForAuthBegin:
                send(context: context, command: .authUser(server.username))
                expect = .okAfterUsername
            case .okAfterUsername:
                send(context: context, command: .authPassword(server.password))
                expect = .okAfterPassword
            case .okAfterPassword:
                send(context: context, command: .mailFrom(email.sender))
                expect = .okAfterMailFrom
            case .okAfterMailFrom:
                send(context: context, command: .recipient(recipient))
                expect = .okAfterRecipient
            case .okAfterRecipient:
                send(context: context, command: .data)
                expect = .okAfterData
            case .okAfterData:
                send(context: context, command: .transferData(email))
                expect = .okAfterTransferData
            case .okAfterTransferData:
                send(context: context, command: .quit)
                expect = .okAfterQuit
            case .okAfterQuit:
                done.succeed()
                context.close(promise: nil)
                expect = .nothing
            case .error(let error):
                fatalError("SMTP.SendHandler.channelRead(context:data:) after error: \(error)")
            case .nothing:
                break
            }
        }
    }

    /// Fail the send with ``SMTPError/remoteConnectionClosed`` when the connection closes.
    func channelInactive(context: ChannelHandlerContext) {
        expect = .error(SMTPError.remoteConnectionClosed)
    }

    /// Fail the send with any error from the pipeline, and close the connection.
    func errorCaught(context: ChannelHandlerContext, error: any Error) {
        expect = .error(error)
        context.close(promise: nil)
    }
}

/// Extends `NIOSSLContext` with the client context used after `STARTTLS`.
private extension NIOSSLContext {
    /// A client TLS context with the default configuration, which verifies the server's certificate. It's the same as
    /// the one in `SMTPClient.swift`.
    static var ssl: Self { try! Self(configuration: .makeClientConfiguration()) }
}

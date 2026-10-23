// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MIME
import NIO
import NIOIMAP
import NIOSSL
import OSLog

/// Configure `IMAPClient` with a single ``Server``.
public class IMAPClient {
    public let server: Server

    public private(set) var capabilities: Set<Capability> = []
    public var isConnected: Bool { channel != nil && channel!.isActive }
    public var isIdling: Bool { idleHandler != nil }

    public func isSupported(_ capability: Capability) throws {
        guard capabilities.contains(capability) else {
            throw IMAPError.capabilityNotSupported(capability)
        }
    }

    /// Bootstrap NIO channel, connect to the configured ``Server``.
    public func connect() async throws {
        logger?.info("Connecting to \(self.server)…")
        resetInactiveChannel()
        guard channel == nil else {
            logger?.error("\(IMAPError.alreadyConnected)")
            throw IMAPError.alreadyConnected
        }
        do {
            self.channel =
                try await ClientBootstrap
                .bootstrap(server: server, logger: logger, group: group)
                .connect(host: server.hostname, port: server.port)
                .get()
            logger?.info("Connected to \(self.server)")
            try await refreshCapabilities()
        } catch {
            logger?.error("\(error)")
            throw IMAPError(error)
        }
    }

    /// Disconnect NIO channel from configured ``Server``; reset to ready for new connection.
    public func disconnect() throws {
        guard let channel else {
            logger?.error("\(IMAPError.notConnected)")
            throw IMAPError.notConnected
        }
        channel.close(promise: nil)
        self.channel = nil
    }

    /// Authenticate with connected IMAP ``Server``. Provided ``Authentication`` overrides `Server` configuration authentication.
    public func authenticate(_ authentication: Authentication? = nil) async throws {
        guard let authentication: Authentication = authentication ?? server.authentication else {
            throw IMAPError.authenticationCredentialNotFound
        }
        logger?.info("Authenticating \(authentication)…")
        switch authentication {
        case .xoauth2:
            try isSupported(.authenticate(.xOAuth2))
            throw IMAPError.commandNotSupported("AUTHENTICATE XOAUTH2")
        case .plain(let user, let password):
            do {
                try isSupported(.saslIR)
                let capabilities: [Capability] = try await execute(command: AuthenticateCommand(authentication))
                merge(capabilities: capabilities)
            } catch {
                try await login(username: user, password: password)
            }
        }
    }

    /// Log in to connected IMAP ``Server`` using basic credentials.
    public func login(username: String, password: String) async throws {
        logger?.info("Logging in \(username)…")
        let capabilities: [Capability] = try await execute(command: LoginCommand(username: username, password: password))
        merge(capabilities: capabilities)
    }

    /// Log out from connected IMAP ``Server``; leave active NIO channel connection intact.
    public func logout() async throws {
        logger?.info("Logging out…")
        try await execute(command: VoidCommand(.logout))
    }

    /// Fetch namespaces available to authenticated user.`
    public func namespace() async throws -> [Namespace] {
        logger?.info("Fetching namespace…")
        let namespace: [Namespace] = try await execute(command: NamespaceCommand())
        logger?.info("Namespaces: \(namespace)")
        return namespace
    }

    /// Start idle on connected ``Server``; handle ``IdleEvent`` pushes.
    @discardableResult public func idle() async throws -> AsyncStream<IdleEvent> {
        try isSupported(.idle)
        logger?.info("Idle start…")
        return try await idleStart()
    }

    /// Stop idling on connected ``Server``.
    public func done() async throws {
        logger?.info("Idle done…")
        try await idleDone()
    }

    /// Poll ``Server`` for ``IdleEvent`` when not idling.
    public func noop() async throws -> [IdleEvent] {
        logger?.info("Noop…")
        guard !isIdling else {
            // NIOIMAP automatically keeps idle alive and streams idle events
            // Manual `noop` polling is blocked by NIOIMAP during idle
            throw IMAPError.commandNotSupported("Noop during idle")
        }
        return try await execute(command: NoopCommand())
    }

    /// List all mailboxes on logged-in IMAP ``Server``.
    public func list(wildcard: Character = .wildcard) async throws -> [(Mailbox, Mailbox.Status?)] {
        logger?.info("Listing mailboxes…")
        return try await execute(command: ListCommand(wildcard: wildcard))
    }

    /// Select current working mailbox in read/write mode.
    @discardableResult public func select(mailbox name: MailboxName) async throws -> Mailbox.Status {
        logger?.info("Selecting mailbox \(name)…")
        return try await execute(command: SelectCommand(name))
    }

    /// Select a working mailbox in read-only mode.
    public func examine(mailbox name: MailboxName) async throws -> Mailbox.Status {
        logger?.info("Examining mailbox \(name)…")
        return try await execute(command: ExamineCommand(name))
    }

    /// Fetch the current status for a mailbox.
    public func status(mailbox name: MailboxName) async throws -> Mailbox.Status {
        logger?.info("Refreshing mailbox \(name) status…")
        return try await execute(command: StatusCommand(name, attributes: .standard + .extended(capabilities)))
    }

    /// Expunge messages flagged as deleted in current working mailbox.
    public func expunge() async throws {
        logger?.info("Expunging selected mailbox…")
        try await execute(command: VoidCommand(.expunge))
    }

    /// Unselect current working mailbox; don't expunge messages flagged as deleted.
    public func unselect() async throws {
        logger?.info("Unselecting mailbox…")
        try await execute(command: VoidCommand(.unselect))
    }

    /// Create a new mailbox.
    public func create(mailbox name: MailboxName) async throws {
        logger?.info("Creating \"\(name)\" mailbox…")
        try await execute(command: CreateCommand(name))
    }

    /// Rename an existing mailbox.
    public func rename(mailbox name: MailboxName, to targetName: MailboxName) async throws {
        logger?.info("Renaming \"\(name)\" mailbox to \"\(targetName)\"…")
        try await execute(command: RenameCommand(name, to: targetName))
    }

    /// Delete an existing mailbox.
    public func delete(mailbox name: MailboxName) async throws {
        logger?.info("Deleting \"\(name)\" mailbox…")
        try await execute(command: DeleteCommand(name))
    }

    /// Subscribe to an existing mailbox.
    public func subscribe(mailbox name: MailboxName) async throws {
        logger?.info("Subscribing \"\(name)\" mailbox…")
        try await execute(command: SubscribeCommand(name))
    }

    /// Unsubscribe from an existing mailbox.
    public func unsubscribe(mailbox name: MailboxName) async throws {
        logger?.info("Unsubscribing \"\(name)\" mailbox…")
        try await execute(command: UnsubscribeCommand(name))
    }

    /// Expunge and unselect current working mailbox.
    public func close() async throws {
        logger?.info("Closing selected mailbox…")
        try await execute(command: VoidCommand(.close))
    }

    /// Fetch a set of messages by mailbox ``SequenceNumber``; fetches all headers and omits message body by default.
    public func fetch(_ set: SequenceSet = .all, attributes: [FetchAttribute] = .header) async throws -> MessageSet {
        logger?.info("Fetching messages by mailbox sequence number…")
        return try await execute(command: FetchCommand(set, attributes: attributes.filtered(capabilities)))
    }

    /// Fetch a specific message by ``SequenceNumber``; fetches complete message by default.
    public func fetch(_ number: SequenceNumber, attributes: [FetchAttribute] = .complete) async throws -> Message {
        logger?.info("Fetching message \(number)…")
        let messages: MessageSet = try await fetch(SequenceSet(number), attributes: attributes)
        guard let message: Message = messages.first?.value else {
            throw IMAPError.commandFailed("Message \(number) not found")
        }
        return message
    }

    /// Fetch a set of messages by ``UID``; fetches all headers and omits message body by default.
    public func fetch(uid set: UIDSet, attributes: [FetchAttribute] = .header) async throws -> MessageSet {
        logger?.info("Fetching messages by UID…")
        return try await execute(command: UIDFetchCommand(set, attributes: attributes.filtered(capabilities)))
    }

    /// Fetch a specific message by ``UID``; fetches complete message by default.
    public func fetch(uid: UID, attributes: [FetchAttribute] = .complete) async throws -> Message {
        logger?.info("Fetching message UID \(uid)…")
        let messages: MessageSet = try await fetch(uid: UIDSet(uid), attributes: attributes)
        guard let message: Message = messages.first?.value else {
            throw IMAPError.commandFailed("Message UID \(uid) not found")
        }
        return message
    }

    public init(
        _ server: Server,
        logger: Logger? = Logger(subsystem: "net.thunderbird", category: "IMAP")
    ) {
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.server = server
        self.logger = logger
    }

    // Run IMAP command through NIO `IMAPClientHandler` in channel and handle results
    private func execute<T: IMAPCommand>(command: T) async throws -> T.Result {
        let logger: Logger? = logger  // Copy logger instead of capturing
        logger?.debug("Executing \(command)…")
        guard let channel, channel.isActive else {
            logger?.error("\(IMAPError.notConnected)")
            throw IMAPError.notConnected
        }
        let promise: EventLoopPromise<T.Result> = channel.eventLoop.makePromise(of: T.Result.self)
        let tag: String = UUID().uuidString(1)  // Hold onto specific auto-generated tag
        let handler: T.Handler = T.Handler(tag: tag, promise: promise)
        let seconds: Int64 = max(command.timeout, 1)
        let task: Scheduled = group.next().scheduleTask(in: .seconds(seconds)) {
            let error: IMAPError = .timedOut(seconds: seconds)
            logger?.error("\(error)")
            promise.fail(error)
        }
        defer {
            channel.pipeline.removeHandler(handler, promise: nil)
            task.cancel()
        }
        do {
            try await channel.pipeline.addHandler(handler).get()
            let message: IMAPClientHandler.Message = IMAPClientHandler.OutboundIn.part(.tagged(command.tagged(tag)))
            try await channel.writeAndFlush(message).get()
            let result: T.Result = try await promise.futureResult.get()
            logger?.debug("\(command.description.capitalized(.sentence)) succeeded")
            if let clientBug = handler.clientBug {
                logger?.debug("CLIENTBUG: \(clientBug)")
            }
            return result
        } catch {
            promise.fail(error)
            logger?.error("\(error)")
            throw IMAPError.commandFailed(command.description)
        }
    }

    // Start idle through NIO `IMAPClientHandler` and stream results from special, long-running handler
    private func idleStart() async throws -> AsyncStream<IdleEvent> {
        let logger: Logger? = logger  // Copy logger instead of capturing
        logger?.debug("Executing idle start…")
        guard !isIdling else {
            throw IMAPError.commandFailed("Idle already started")
        }
        guard let channel, channel.isActive else {
            logger?.error("\(IMAPError.notConnected)")
            throw IMAPError.notConnected
        }
        var continuation: AsyncStream<IdleEvent>.Continuation?
        let idleEvents: AsyncStream<IdleEvent> = AsyncStream { continuation = $0 }
        let promise: EventLoopPromise<Void> = channel.eventLoop.makePromise(of: Void.self)
        let tag: String = UUID().uuidString(1)  // Hold onto specific auto-generated tag
        idleHandler = IdleHandler(tag: tag, promise: promise, continuation: continuation)
        let seconds: Int64 = .timeout
        let task: Scheduled = group.next().scheduleTask(in: .seconds(seconds)) {
            let error: IMAPError = .timedOut(seconds: seconds)
            logger?.error("\(error)")
            promise.fail(error)
        }
        defer { task.cancel() }
        do {
            try await channel.pipeline.addHandler(idleHandler!).get()
            let command: TaggedCommand = TaggedCommand(tag: tag, command: .idleStart)
            let message: IMAPClientHandler.Message = IMAPClientHandler.OutboundIn.part(.tagged(command))
            try await channel.writeAndFlush(message).get()
            return idleEvents
        } catch {
            promise.fail(error)
            logger?.error("\(error)")
            idleHandler = nil
            throw IMAPError.commandFailed("Idle start failed")
        }
    }

    // End idle and clean up
    private func idleDone() async throws {
        guard let channel, channel.isActive else {
            logger?.error("\(IMAPError.notConnected)")
            throw IMAPError.notConnected
        }
        guard let idleHandler else { return }
        try? await channel.writeAndFlush(IMAPClientHandler.OutboundIn.part(.idleDone)).get()
        logger?.info("Idle done")
        defer {
            channel.pipeline.removeHandler(idleHandler, promise: nil)
            self.idleHandler = nil
        }
        try await idleHandler.promise.futureResult.get()
    }

    private func refreshCapabilities() async throws {
        logger?.info("Refreshing capabilities…")
        capabilities = Set(try await execute(command: CapabilityCommand()))
        logger?.info("Capabilities: \(self.capabilities)")
    }

    private func resetInactiveChannel() {
        guard let channel, !channel.isActive else { return }
        self.channel = nil
        logger?.info("Channel reset; ready to connect")
    }

    private func merge(capabilities: [Capability]) {
        guard !capabilities.isEmpty else { return }
        logger?.info("Merging capabilities…")
        for capability in capabilities {
            self.capabilities.insert(capability)
        }
        logger?.info("Capabilities: \(self.capabilities)")
    }

    private var idleHandler: IdleHandler?
    private var channel: Channel?
    private var count: Int = 0
    private let group: EventLoopGroup
    private let logger: Logger?
}

extension Character {
    public static let delimiter: Self = "."
    public static let wildcard: Self = "*"

    static let prefix: Self = "a"
}

private extension ClientBootstrap {
    static func bootstrap(
        server: Server,
        logger: Logger? = nil,
        group: EventLoopGroup
    ) -> Self {
        Self(group: group).channelInitializer { channel in
            try! channel.pipeline.syncOperations.addHandlers(
                [
                    // LoggingHandler(logger), // Enable byte-level logging
                    TLSClientHandler(serverHostname: server.hostname),
                    IMAPClientHandler(parserOptions: .max)
                ]
            )
            return channel.eventLoop.makeSucceededFuture(())
        }
    }
}

private extension NIOSSLContext {
    static var ssl: Self { try! Self(configuration: .makeClientConfiguration()) }
}

private func TLSClientHandler(serverHostname: String? = nil) -> NIOSSLClientHandler {
    try! NIOSSLClientHandler(context: .ssl, serverHostname: serverHostname)
}

private extension ResponseParser.Options {
    static var max: Self {
        Self(
            bufferLimit: 1024 * 1024,
            messageAttributeLimit: .max,
            bodySizeLimit: .max,
            literalSizeLimit: IMAPDefaults.literalSizeLimit
        )
    }
}

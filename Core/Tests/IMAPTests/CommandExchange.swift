// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import IMAP
import NIOCore
import NIOEmbedded
import NIOIMAP

/// A test double for the server side of one IMAP command: the test reads what the client sent and scripts each reply.
///
/// ## Why tests need it
///
/// An `IMAPCommand` has two halves. `tagged(_:)` decides the bytes that go to the server, and the command's `Handler`
/// turns the server's replies into a result or an error. In the app both halves only run inside `IMAPClient.execute`,
/// which is private and needs a live connection. Without a scripted connection that leaves two ways to test a
/// command, and neither is enough:
///
/// - Against a real server (`IMAPClientTests.allCommands`). It needs a mail account, so its servers are disabled
///   unless a developer fills in credentials locally, and the test can't choose what the server says. There is no way
///   to make a real server answer `BAD`, leave out an extension, or reply in a particular order on demand.
/// - On the command's own properties (`VoidCommandTests`). That never encodes the command or runs its handler, so it
///   can't tell what is sent or how a reply is read.
///
/// `CommandExchange` covers the gap. It is the server, written out line by line in the test, so a test can pin down
/// the exact command on the wire and how each possible reply is handled, with no network and no account.
///
/// `Exchange` in `AuthenticateCommandTests` does the same for `AUTHENTICATE` alone; this one takes any command.
///
/// ## What it does
///
/// 1. Builds the pipeline `IMAPClient` builds for a real connection, minus TLS and the socket: NIOIMAP's
///    `IMAPClientHandler`, which encodes commands and parses responses, followed by the command's own `Handler`.
/// 2. Puts that pipeline on an `EmbeddedChannel` in place of a network connection. Nothing leaves the process, and
///    everything runs synchronously on the calling thread, so there is nothing to wait for or time out.
/// 3. Writes the command, as `IMAPClient.execute` does. `sent()` then returns the bytes the client put on the wire.
/// 4. Lets the test play the server: each `receive(_:)` delivers one line, which is parsed and passed to the handler.
/// 5. Records how the command ended in `outcome`, with `result` and `error` as shortcuts, once the handler completes
///    it. Until then all three are `nil`.
///
/// A test reads top to bottom as the conversation it describes:
///
/// ```swift
/// let exchange = try CommandExchange(ListCommand(options: [], wildcard: "*"))
/// #expect(try exchange.sent() == "A01 LIST \"\" \"*\"\r\n")  // What the client sent
/// try exchange.receive("* LIST () \".\" \"INBOX\"")           // What the server says back
/// try exchange.receive("A01 OK LIST completed.")
/// #expect(exchange.result?.count == 1)                         // What the handler made of it
/// ```
///
/// - Important: It tests one command and its handler, not `IMAPClient`. The parts of `IMAPClient.execute` around the
///   command aren't exercised: the timeout, the generated tag, removing the handler afterwards, and the capability
///   checks a client method makes before it builds the command. Build the command the way the client method does
///   (for example with the same filtered options) to cover that choice.
final class CommandExchange<Command: IMAPCommand> {
    /// How the command ended; `nil` while it is still waiting for the server.
    var outcome: Result<Command.Result, IMAPError>? { recorder.outcome }

    /// Start the exchange by writing the command to the connection, as `IMAPClient.execute` does.
    ///
    /// - Parameters:
    ///   - command: The command to send.
    ///   - tag: The tag to send it with. Give the scripted tagged reply the same one, as a server would.
    /// - Throws: An error from NIO if the pipeline can't be built or the command can't be encoded.
    init(_ command: Command, tag: String = "A01") throws {
        promise = channel.eventLoop.makePromise(of: Command.Result.self)
        // Record the outcome when it arrives. `wait()` isn't an option: on an embedded event loop, waiting for a
        // command the server hasn't finished would block the test forever. The callback keeps the recorder alive
        // and not `self`, because `deinit` below can be what triggers it.
        promise.futureResult.assumeIsolated().whenComplete { [recorder] result in
            recorder.outcome = result.mapError { IMAPError($0) }
        }
        try channel.pipeline.syncOperations.addHandler(IMAPClientHandler())
        try channel.pipeline.syncOperations.addHandler(Command.Handler(tag: tag, promise: promise))
        try channel.writeOutbound(IMAPClientHandler.Message.part(.tagged(command.tagged(tag))))
    }

    deinit {
        // NIO treats a promise that is dropped without a result as a bug and traps. A test that fails partway
        // through would otherwise take the whole test run down with it. Does nothing if the command has ended.
        promise.fail(IMAPError.notConnected)
    }

    /// What the command produced, if it succeeded.
    var result: Command.Result? {
        guard case .success(let result) = outcome else { return nil }
        return result
    }

    /// The error the command failed with, if it failed.
    var error: IMAPError? {
        guard case .failure(let error) = outcome else { return nil }
        return error
    }

    /// Delivers one line from the server; the line ending is added here.
    func receive(_ line: String) throws {
        try channel.writeInbound(ByteBuffer(string: "\(line)\r\n"))
    }

    /// Everything the client has put on the wire since the last call, line endings included.
    func sent() throws -> String {
        var sent: String = ""
        while let buffer: ByteBuffer = try channel.readOutbound(as: ByteBuffer.self) {
            sent += String(buffer: buffer)
        }
        return sent
    }

    private final class Recorder {
        var outcome: Result<Command.Result, IMAPError>?
    }

    private let channel: EmbeddedChannel = EmbeddedChannel()
    private let promise: EventLoopPromise<Command.Result>
    private let recorder: Recorder = Recorder()
}

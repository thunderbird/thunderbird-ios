// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import IMAP
import NIOCore
import NIOEmbedded
import NIOIMAP

/// One command's exchange with a scripted server.
///
/// The pipeline is the one `IMAPClient` builds for a real connection, minus TLS and the socket: NIOIMAP's
/// `IMAPClientHandler` (which encodes commands and parses responses) followed by the command's own handler. An
/// `EmbeddedChannel` stands in for the network. It runs everything synchronously on the calling thread, so a test
/// reads top to bottom as the conversation it describes: what the client `sent()`, then what it is made to `receive(_:)`.
final class CommandExchange<Command: IMAPCommand> {
    /// How the command ended; `nil` while it is still waiting for the server.
    var outcome: Result<Command.Result, IMAPError>? { recorder.outcome }

    /// Starts the exchange by writing the command, as `IMAPClient.execute` does.
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

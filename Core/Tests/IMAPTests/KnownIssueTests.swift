// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import IMAP
import NIOCore
import NIOEmbedded
import NIOIMAP
import Testing

// Tests for behavior that is known to be wrong today. Each one states what should happen and is expected to fail
// until its issue is fixed.
//
// `withKnownIssue` records the failure as a known issue, so the suite stays green. When a fix lands the expectation
// starts to pass, the test then fails with "known issue was not encountered", and the `withKnownIssue` wrapper
// has to be removed. The `.bug` trait links each test to its issue.
//
// Both tests script the server's reply to one command, using the handlers `IMAPClient` puts on a real connection.
struct KnownIssueTests {
    //Expect: Report the capabilities the server announced.
    //Case: When the server answers LOGIN with the capability list in a response code of the tagged OK
    //  (RFC 3501, section 6.2.3).
    @Test(.bug("https://github.com/thunderbird/thunderbird-ios/issues/662", "IMAP: capabilities announced after sign-in are added to the old list, and never requested if the server sends none"))
    func login_collectsCapabilities_whenOKCarriesCapabilityResponseCode() throws {
        // Arrange
        let command: LoginCommand = LoginCommand(username: "user", password: "password")

        // Act
        let outcome = try Self.outcome(of: command, whenServerSends: "A01 OK [CAPABILITY IMAP4rev1 IDLE] Logged in")
        let actual = (try? outcome?.get())?.contains(.idle)

        // Assert
        withKnownIssue("Tracked in #662") {
            #expect(actual == true)
        }
    }

    //Expect: Not report a rejected credential.
    //Case: When the server refuses a sign-in with `[UNAVAILABLE]`, which means a temporary failure on its side
    //  (RFC 5530, section 3).
    @Test(.bug("https://github.com/thunderbird/thunderbird-ios/issues/665", "IMAP: server response codes are dropped, so a temporary outage looks like a rejected sign-in"))
    func authenticate_doesNotReportRejectedCredential_whenServerIsUnavailable() throws {
        // Arrange
        let command: AuthenticateCommand = AuthenticateCommand(.xoauth2("user", token: "token"))

        // Act
        let outcome = try Self.outcome(of: command, whenServerSends: "A01 NO [UNAVAILABLE] Temporary authentication failure")
        var actual: Bool = false
        if case .failure(let error)? = outcome, case .authenticationFailed = IMAPError(error) {
            actual = true
        }

        // Assert
        withKnownIssue("Tracked in #665") {
            #expect(actual == false)
        }
    }

    // Write `command` with tag A01, deliver one line from the server, and return how the command ended
    private static func outcome<T: IMAPCommand>(of command: T, whenServerSends line: String) throws -> Result<T.Result, Error>? {
        let channel: EmbeddedChannel = EmbeddedChannel()
        let promise: EventLoopPromise<T.Result> = channel.eventLoop.makePromise(of: T.Result.self)
        let recorder: Recorder<T.Result> = Recorder()
        promise.futureResult.assumeIsolated().whenComplete { recorder.outcome = $0 }
        // NIO traps on a promise dropped without a result; make sure a test that fails early can't leave one
        defer { promise.fail(IMAPError.notConnected) }
        try channel.pipeline.syncOperations.addHandler(IMAPClientHandler())
        try channel.pipeline.syncOperations.addHandler(command.handler(tag: "A01", promise: promise))
        try channel.writeOutbound(IMAPClientHandler.Message.part(.tagged(command.tagged("A01"))))
        try channel.writeInbound(ByteBuffer(string: "\(line)\r\n"))
        return recorder.outcome
    }
}

private final class Recorder<Value> {
    var outcome: Result<Value, Error>?
}

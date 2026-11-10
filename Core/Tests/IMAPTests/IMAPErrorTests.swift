// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import IMAP
import NIOCore
import Testing

struct IMAPErrorTests {

    // `IMAPClient` reports a failed command as "command failed", whatever the cause, with one exception: a rejected
    // credential keeps its identity and its detail, because the account layer has to act on it differently
    @Test func executing() {
        let command: CapabilityCommand = CapabilityCommand()

        // Passed through untouched, server's reason included
        let failure: AuthenticationFailure? = AuthenticationFailure(ByteBuffer(string: #"{"status":"401","schemes":"bearer","scope":"scope"}"#))
        let rejected: IMAPError = IMAPError(IMAPError.authenticationFailed("SASL authentication failed", failure: failure), executing: command)
        guard case .authenticationFailed(let description, let passedThrough) = rejected else {
            Issue.record("Expected authenticationFailed, got \(rejected)")
            return
        }
        #expect(description == "SASL authentication failed")
        #expect(passedThrough == failure)
        #expect(passedThrough?.schemes == "bearer")

        // Everything else is flattened to the command that failed
        #expect(IMAPError(IMAPError.timedOut(seconds: 60), executing: command) == .commandFailed("capability command"))
        #expect(IMAPError(IMAPError.commandFailed("Invalid SASL argument"), executing: command) == .commandFailed("capability command"))
        #expect(IMAPError(IMAPError.notConnected, executing: command) == .commandFailed("capability command"))
        #expect(IMAPError(URLError(.networkConnectionLost), executing: command) == .commandFailed("capability command"))
    }

    // MARK: CustomStringConvertible
    @Test func description() {
        #expect(IMAPError.authenticationFailed("SASL authentication failed").description == "Authentication failed: SASL authentication failed")
        #expect(
            IMAPError.authenticationFailed(
                "SASL authentication failed",
                failure: AuthenticationFailure(ByteBuffer(string: #"{"status":"invalid_token","scope":"example_scope"}"#))
            ).description == "Authentication failed: SASL authentication failed (invalid_token, scope: example_scope)")
        #expect(IMAPError.capabilityNotSupported(.idle).description == "IDLE not supported")
        #expect(IMAPError.commandFailed("CAPABILITY failed.").description == "CAPABILITY failed.")
        #expect(IMAPError.commandFailed(CapabilityCommand()).description == "Capability command failed")
        #expect(IMAPError.commandNotSupported("capability command").description == "Capability command not supported")
        #expect(IMAPError.commandNotSupported(CapabilityCommand()).description == "Capability command not supported")
        #expect(IMAPError.timedOut(seconds: 5).description == "Timed out after 5 seconds")
        #expect(IMAPError.timedOut(seconds: 0).description == "Timed out after 0 seconds")
        #expect(IMAPError.timedOut(seconds: 1).description == "Timed out after 1 second")
        #expect(IMAPError.underlying(URLError(.badURL)).description == "Underlying error: The operation couldn’t be completed. (NSURLErrorDomain error -1000.)")
    }
}

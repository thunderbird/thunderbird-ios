// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import IMAP
import NIOCore
import Testing

struct IMAPErrorTests {

    // `IMAPClient` reports a failed command as "command failed", whatever the cause, with one exception: a rejected
    // credential keeps its identity and its detail, because the account layer has to act on it differently.

    //Expect: Pass the error through unchanged, the server's reason included.
    //Case: When the command failed because the server rejected the credential.
    @Test func init_passesErrorThrough_whenCommandFailedWithRejectedCredential() {
        // Arrange
        let failure = AuthenticationFailure(ByteBuffer(string: #"{"status":"401","schemes":"bearer","scope":"scope"}"#))
        let input: IMAPError = .authenticationFailed("SASL authentication failed", failure: failure)

        // Act
        var actual: AuthenticationFailure?
        if case .authenticationFailed("SASL authentication failed", let passedThrough) = IMAPError(input, executing: CapabilityCommand()) {
            actual = passedThrough
        }

        // Assert
        #expect(actual == failure)
    }

    //Expect: Report that the command failed, naming the command.
    //Case: When the command failed for any other reason: a timeout, a failure reported by the server, a lost
    //  connection, or an error from outside the IMAP module.
    @Test(arguments: [
        IMAPError.timedOut(seconds: 60) as any Error,
        IMAPError.commandFailed("Invalid SASL argument"),
        IMAPError.notConnected,
        URLError(.networkConnectionLost)
    ])
    func init_reportsCommandFailed_whenCommandFailedForAnotherReason(_ input: any Error) {
        // Arrange
        let expected: IMAPError = .commandFailed("capability command")

        // Act
        let actual = IMAPError(input, executing: CapabilityCommand())

        // Assert
        #expect(actual == expected)
    }

    //Expect: Describe the failure with the server's text, followed by its reason when it gave one.
    //Case: When a rejected credential is described, with and without a reason.
    @Test(arguments: [
        (nil as String?, "Authentication failed: SASL authentication failed"),
        (#"{"status":"invalid_token","scope":"example_scope"}"#, "Authentication failed: SASL authentication failed (invalid_token, scope: example_scope)")
    ])
    func description_showsServerTextAndReason_whenCredentialIsRejected(_ errorResult: String?, _ expected: String) {
        // Arrange
        let failure = errorResult.flatMap { AuthenticationFailure(ByteBuffer(string: $0)) }
        let input: IMAPError = .authenticationFailed("SASL authentication failed", failure: failure)

        // Act
        let actual = input.description

        // Assert
        #expect(actual == expected)
    }

    // MARK: CustomStringConvertible
    @Test func description() {
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

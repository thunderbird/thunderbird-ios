// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Represents the result of a test, including success and error cases.
public enum TestResult: CustomStringConvertible, Identifiable, Sendable {
    /// A test failure with a description and error.
    case failure(String, error: Error)
    /// A successful test with a descriptive message.
    case success(String)

    /// True if the result represents a failure.
    public var isFailure: Bool { error != nil }

    /// Associated error if the result is a failure.
    public var error: Error? {
        switch self {
        case .failure(_, let error): error
        case .success: nil
        }
    }

    /// Required for `CustomStringConvertible` conformance.
    public var description: String {
        switch self {
        case .failure(let description, _), .success(let description): description
        }
    }

    /// Required for `Identifiable` conformance.
    public var id: String {
        switch self {
        case .failure(let string, _): "\(string):x"
        case .success(let string): string
        }
    }
}

/// Extends `Account` with custom validation functions.
extension Account {
    /// Runs basic validations for both IMAP/SMTP and JMAP account configurations asynchronously.
    ///
    /// - Parameters:
    ///  - duration: The duration to sleep the Task before resuming operations. Currently used for effect. Defaults to 1 second.
    @MainActor
    public func test(sleep duration: Duration = .milliseconds(100)) -> AsyncStream<TestResult> {
        let account: Self = self
        return AsyncStream { continuation in
            Task {
                switch account.emailProtocol {
                case .imap:
                    var description: String = "IMAP CONNECT"
                    do {
                        guard let incomingServer: Server = account.incomingServer else {
                            throw IMAPError.serverProtocolMismatch
                        }
                        let client: IMAPClient = IMAPClient(try IMAP.Server(incomingServer, authorization: authorization))
                        try await client.connect()
                        continuation.yield(.success(description))
                        description = "IMAP AUTHENTICATE"
                        try await client.authenticate()
                        continuation.yield(.success(description))
                        for capability in client.capabilities {
                            try await Task.sleep(for: duration)  // Just for drama
                            continuation.yield(.success("IMAP \(capability)"))
                        }
                        try await client.logout()
                        description = "SMTP SEND"
                        guard let outgoingServer: Server = account.outgoingServer else {
                            throw SMTPError.serverProtocolMismatch
                        }
                        let _: SMTPClient = SMTPClient(try SMTP.Server(outgoingServer, authorization: authorization))
                        continuation.yield(.success(description))
                    } catch {
                        continuation.yield(.failure(description, error: error))
                    }
                case .jmap:
                    do {
                        guard let server: Server = account.servers.first else {
                            throw JMAPError.serverProtocolMismatch
                        }
                        let client: JMAPClient = try await .session(try JMAP.Server(server, authorization: authorization))
                        guard let session: Session = client.session else {
                            throw JMAPError.sessionNotFound
                        }
                        continuation.yield(.success("JMAP SESSION"))
                        for capability in session.capabilities.sorted(by: { $0.0.rawValue < $1.0.rawValue }) {
                            try await Task.sleep(for: duration)  // Just for drama
                            continuation.yield(.success("JMAP \(capability.key.description.uppercased())"))
                        }
                    } catch {
                        continuation.yield(.failure("JMAP SESSION", error: error))
                    }
                }
                continuation.finish()
            }
        }
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MIME
import NIOIMAPCore

/// ``IMAPClient`` throws `IMAPError`.
public enum IMAPError: Error, CustomStringConvertible, Equatable {
    case alreadyConnected
    case authenticationCredentialNotFound
    case authenticationEncodingFailed(_ description: String)

    /// The server rejected the credential sent with `AUTHENTICATE`, ending the command with a tagged `NO`.
    ///
    /// Unlike a timeout or a dropped connection, retrying the same command can't fix this: the credential itself
    /// has to change. For OAuth that means refreshing the access token or signing in again. ``IMAPClient``
    /// therefore reports it as its own case, where every other failed command becomes ``commandFailed(_:)``.
    ///
    /// - Parameters:
    ///   - description: The human-readable text of the server's `NO` response, such as `SASL authentication failed`.
    ///   - failure: The error result the server sent in a challenge before the `NO`; `nil` when it sent none or
    ///     sent something that isn't an OAuth error result. `PLAIN` never has one.
    case authenticationFailed(_ description: String, failure: AuthenticationFailure? = nil)

    case capabilityNotSupported(_ description: String)
    case commandFailed(_ description: String)
    case commandNotSupported(_ description: String)
    case notConnected
    case serverDisconnected
    case timedOut(seconds: Int64)
    case underlying(_ error: Error)  // Wrap NIO errors
    case unexpectedResponse(_ description: String)

    init(_ error: Error) {
        self = error as? Self ?? .underlying(error)
    }

    /// Map the error that ended a command to the error ``IMAPClient`` throws for it.
    ///
    /// Almost every failure is flattened into ``commandFailed(_:)`` naming the command, because callers act on
    /// "this command didn't work" and not on the transport detail behind it. The exception is
    /// ``authenticationFailed(_:failure:)``, which passes through untouched: flattening it would hide the one
    /// fact the account layer needs in order to refresh an expired token instead of retrying or giving up.
    ///
    /// - Parameters:
    ///   - error: The error the command's promise failed with, or the error thrown while writing the command.
    ///   - command: The command that was being executed.
    init(_ error: Error, executing command: any IMAPCommand) {
        if let error: Self = error as? Self, case .authenticationFailed = error {
            self = error
        } else {
            self = .commandFailed(command.description)
        }
    }

    static func capabilityNotSupported(_ capability: Capability) -> Self {
        .capabilityNotSupported("\(capability)")
    }

    static func commandFailed(_ command: any IMAPCommand) -> Self {
        .commandFailed("\(command) failed")
    }

    static func commandNotSupported(_ command: any IMAPCommand) -> Self {
        .commandNotSupported(command.description)
    }

    static func unexpectedResponse(_ text: ResponseText) -> Self {
        .unexpectedResponse(text.text)
    }

    // MARK: CustomStringConvertible
    public var description: String {
        switch self {
        case .alreadyConnected: "Already connected"
        case .authenticationCredentialNotFound: "Authentication credential not found"
        case .authenticationEncodingFailed(let description): "Authentication failed SASL encoding: \(description)"
        case .authenticationFailed(let description, let failure):
            // Lead with the server's own words; append the decoded error result when there is one
            "Authentication failed: \(description)" + (failure.map { " (\($0))" } ?? "")
        case .capabilityNotSupported(let description), .commandNotSupported(let description): "\(description.capitalized(.sentence)) not supported"
        case .commandFailed(let description): "\(description.capitalized(.sentence))"
        case .notConnected: "Not connected"
        case .serverDisconnected: "Server disconnected"
        case .timedOut(let seconds): "Timed out after \(seconds) \(seconds == 1 ? "second" : "seconds")"
        case .underlying(let error): "Underlying error: \(error.localizedDescription)"
        case .unexpectedResponse(let description): "Unexpected response: \(description)"
        }
    }

    // MARK: Equatable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.description == rhs.description
    }
}

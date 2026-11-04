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

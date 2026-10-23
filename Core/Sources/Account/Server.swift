// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Autoconfiguration
import EmailAddress
import Foundation
import IMAP
import JMAP
import MIME
import SMTP

/// All supported server types enumerated.
public enum ServerProtocol: String, Codable, CaseIterable, CustomStringConvertible, Identifiable, Sendable {
    case imap = "IMAP"
    case jmap = "JMAP"
    case smtp = "SMTP"

    // MARK: CustomStringConvertible
    public var description: String { rawValue }

    // MARK: Identifiable
    public var id: String { rawValue }
}

/// General purpose server model for any supported `ServerProtocol`. Stores authorization credentials locally in the [Apple keychain.](https://developer.apple.com/documentation/security/storing-keys-in-the-keychain)
public struct Server: Codable, Equatable, Hashable, Identifiable, Sendable {
    public typealias ConnectionSecurity = IMAP.ConnectionSecurity

    public var serverProtocol: ServerProtocol
    public var connectionSecurity: ConnectionSecurity
    public var authenticationType: AuthenticationType
    public var username: String
    public var hostname: String
    public var port: Int

    public init(
        _ serverProtocol: ServerProtocol,
        connectionSecurity: ConnectionSecurity = .none,
        authenticationType: AuthenticationType = .none,
        username: String = "",
        hostname: String = "",
        port: Int? = nil,
        id: UUID = UUID()
    ) {
        self.serverProtocol = serverProtocol
        self.connectionSecurity = connectionSecurity
        self.authenticationType = authenticationType
        self.username = username
        self.hostname = hostname
        self.port = port ?? serverProtocol.defaultPort
        self.id = id
    }

    // MARK: Identifiable
    public let id: UUID
}

extension ServerProtocol {
    public var defaultPort: Int {
        switch self {
        case .imap: IMAP.Server(hostname: "").port
        case .jmap: JMAP.Server(authorization: nil, host: "").port
        case .smtp: SMTP.Server(hostname: "", username: "", password: "").port
        }
    }

    init?(_ serverType: EmailProvider.Server.ServerType) {
        switch serverType {
        case .imap:
            self = .imap
        case .smtp:
            self = .smtp
        case .pop3:
            return nil  // POP3 is not supported
        }
    }
}

// MARK: IMAP
extension IMAPError {
    public static var oAuth2NotSupported: Self { .capabilityNotSupported("OAuth2 not supported") }
    public static var serverProtocolMismatch: Self { .capabilityNotSupported("Server protocol mismatch") }
}

extension IMAP.Server {
    public init(_ server: Server, authorization: Authorization) throws {
        guard server.serverProtocol == .imap else {
            throw IMAPError.serverProtocolMismatch
        }
        self.init(
            IMAP.ConnectionSecurity(server.connectionSecurity),
            authentication: Authentication(authorization: authorization),
            hostname: server.hostname,
            port: server.port
        )
    }
}

extension IMAP.Authentication {
    init?(authorization: Authorization) {
        switch authorization {
        case .oauth(let user, let token, _):
            self = .xoauth2(user, token: token.value)
        case .basic(let user, let password):
            self = .plain(user, password: password)
        case .none:
            return nil
        }
    }
}

// MARK: JMAP
extension JMAPError {
    public static var oAuth2NotSupported: Self { .underlying(URLError(.resourceUnavailable)) }
    public static var serverProtocolMismatch: Self { .underlying(URLError(.unsupportedURL)) }
    public static var sessionNotFound: Self { .underlying(URLError(.fileDoesNotExist)) }
}

extension JMAP.Server {
    public init(_ server: Server, authorization: Authorization) throws {
        guard server.serverProtocol == .jmap else {
            throw JMAPError.serverProtocolMismatch
        }
        self.init(authorization: .bearer(authorization.rawValue), host: server.hostname, port: server.port)
    }
}

// MARK: SMTP
extension SMTPError {
    public static var oAuth2NotSupported: Self { .response("OAuth2 not supported") }
    public static var serverProtocolMismatch: Self { .response("Server protocol mismatch") }
}

extension SMTP.Server {
    public init(_ server: Server, authorization: Authorization) throws {
        guard server.serverProtocol == .smtp else {
            throw SMTPError.serverProtocolMismatch
        }
        guard server.connectionSecurity != .tls else {
            throw SMTPError.requiredTLSNotConfigured
        }
        guard server.authenticationType != .oAuth2 else {
            throw SMTPError.serverProtocolMismatch
        }
        self.init(hostname: server.hostname, username: server.username, password: authorization.rawValue)
    }
}

// MARK: Autoconfiguration
extension Server {
    init?(_ server: EmailProvider.Server) {
        guard let serverProtocol: ServerProtocol = ServerProtocol(server.serverType) else {
            return nil  // App only supports IMAP and SMTP
        }
        self.init(
            serverProtocol,
            connectionSecurity: ConnectionSecurity(server.socketType),
            authenticationType: AuthenticationType(server.authentication),
            username: server.username,
            hostname: server.hostname,
            port: server.port
        )
    }
}

extension Server.ConnectionSecurity {
    init(_ socketType: EmailProvider.Server.SocketType, for serverProtocol: ServerProtocol? = nil) {
        switch socketType {
        case .ssl:
            guard serverProtocol != .smtp else { fallthrough }  // SMTP only supports STARTTLS; override autoconfig
            self = .tls
        case .startTLS:
            self = .startTLS
        }
    }
}

private extension Authorization {
    var rawValue: String {
        switch self {
        case .basic(_, let password): password
        case .oauth(_, let token, _): token.value
        case .none: ""
        }
    }
}

private extension IMAP.ConnectionSecurity {
    init(_ connectionSecurity: Server.ConnectionSecurity) {
        switch connectionSecurity {
        case .tls: self = .tls
        case .startTLS: self = .startTLS
        case .none: self = .none
        }
    }
}

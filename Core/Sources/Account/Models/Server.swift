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

/// This file defines the general-purpose `Server` model and the `ServerProtocol` enumeration
/// as well as bridging initializers and helpers that adapt these types to IMAP, JMAP, and SMTP client implementations.
/// It also includes convenience error cases and autoconfiguration mappings.

/// All supported server types enumerated.
public enum ServerProtocol: String, Codable, CaseIterable, CustomStringConvertible, Identifiable, Sendable {
    case imap = "IMAP"
    case jmap = "JMAP"
    case smtp = "SMTP"

    /// Required for `CustomStringConvertible` conformance.
    public var description: String { rawValue }

    /// Required for `Identifiable` conformance.
    public var id: String { rawValue }
}

/// General purpose server model for any supported `ServerProtocol`.
/// Stores authorization credentials locally in the Keychain.
public struct Server: Codable, Equatable, Hashable, Identifiable, Sendable {
    /// The connection security options supported by mail servers.
    ///
    /// This alias maps to the IMAP client's `ConnectionSecurity` to share the same cases across protocols.
    public typealias ConnectionSecurity = IMAP.ConnectionSecurity

    public var serverProtocol: ServerProtocol
    public var connectionSecurity: ConnectionSecurity
    public var authenticationType: AuthenticationType
    public var username: String
    public var hostname: String
    public var port: Int

    /// Creates a new server configuration.
    ///
    /// - Parameters:
    ///   - serverProtocol: The protocol implemented by the server.
    ///   - connectionSecurity: The transport security to use. Defaults to `.none`.
    ///   - authenticationType: The authentication mechanism to use. Defaults to `.none`.
    ///   - username: The username for authentication. Defaults to an empty string.
    ///   - hostname: The server hostname. Defaults to an empty string.
    ///   - port: An optional explicit port. If `nil`, the protocol's `defaultPort` is used.
    ///   - id: A unique identifier for this configuration. Defaults to a new `UUID`.
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

    /// Required for `Identifiable` conformance.
    public let id: UUID
}

/// Extends `ServerProtocol` with default port conformance and convenience initalizers
extension ServerProtocol {
    /// The default TCP port for this protocol.
    ///
    /// - Returns: The standard port number used by the underlying client implementation.
    public var defaultPort: Int {
        switch self {
        case .imap: IMAP.Server(hostname: "").port
        case .jmap: JMAP.Server(authorization: nil, host: "").port
        case .smtp: SMTP.Server(hostname: "", username: "", password: "").port
        }
    }

    /// Creates a `ServerProtocol` from an autoconfiguration server type.
    ///
    /// - Parameter serverType: The autoconfiguration server type.
    /// - Returns: A matching protocol, or `nil` when the server type is unsupported (e.g., POP3).
    init?(_ serverType: EmailProvider.Server.ServerType) {
        switch serverType {
        case .imap: self = .imap
            //TODO: Expand when JMAP support is added.
//        case .jmap: self = .jmap
        case .smtp: self = .smtp
        case .pop3: return nil
        }
    }
}

/// Extends `IMAPError` with additional error reasons.
extension IMAPError {
    /// Error indicating the server does not support OAuth 2.0.
    public static var oAuth2NotSupported: Self { .capabilityNotSupported("OAuth2 not supported") }

    /// Error indicating the provided configuration is not for an IMAP server.
    public static var serverProtocolMismatch: Self { .capabilityNotSupported("Server protocol mismatch") }
}

/// Extends `IMAP.Server` for creating an IMAP server from a generic `Server`.
extension IMAP.Server {
    /// Creates an IMAP server instance from a generic `Server` and credentials.
    ///
    /// - Parameters:
    ///   - server: The generic server configuration which must specify the IMAP protocol.
    ///   - authorization: The credentials to use for authentication.
    /// - Throws: `IMAPError.serverProtocolMismatch` when `server.serverProtocol` is not `.imap`.
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

/// Extends `IMAP.Authentication` with convenience initializers from generic Authorization
extension IMAP.Authentication {
    /// Creates an IMAP authentication value from a generic authorization.
    ///
    /// - Parameter authorization: The generic credentials.
    /// - Returns: A concrete IMAP authentication method, or `nil` when no authentication is required.
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

/// Extends `JMAPError` with additional error reasons.
extension JMAPError {
    /// Error indicating OAuth 2.0 is not supported for this JMAP configuration.
    public static var oAuth2NotSupported: Self { .underlying(URLError(.resourceUnavailable)) }

    /// Error indicating the provided configuration is not for a JMAP server.
    public static var serverProtocolMismatch: Self { .underlying(URLError(.unsupportedURL)) }

    /// Error indicating that the JMAP session could not be found.
    public static var sessionNotFound: Self { .underlying(URLError(.fileDoesNotExist)) }
}

/// Extends `JMAP.Server` for creating a JMAP server from a generic `Server`.
extension JMAP.Server {
    /// Creates a JMAP server instance from a generic `Server` and credentials.
    ///
    /// - Parameters:
    ///   - server: The generic server configuration which must specify the JMAP protocol.
    ///   - authorization: The credentials to use for authentication.
    /// - Throws: `JMAPError.serverProtocolMismatch` when `server.serverProtocol` is not `.jmap`.
    public init(_ server: Server, authorization: Authorization) throws {
        guard server.serverProtocol == .jmap else {
            throw JMAPError.serverProtocolMismatch
        }
        self.init(authorization: .bearer(authorization.rawValue), host: server.hostname, port: server.port)
    }
}

/// Extends `SMTPError` with additional error reasons.
extension SMTPError {
    /// Error indicating OAuth 2.0 is not supported for this SMTP configuration.
    public static var oAuth2NotSupported: Self { .response("OAuth2 not supported") }
    /// Error indicating the provided configuration is not for an SMTP server.
    public static var serverProtocolMismatch: Self { .response("Server protocol mismatch") }
}

/// Extends `SMTP.Server` with convenience initializers for generic servers.
extension SMTP.Server {
    /// Creates an SMTP server instance from a generic `Server` and credentials.
    ///
    /// - Parameters:
    ///   - server: The generic server configuration which must specify the SMTP protocol.
    ///   - authorization: The credentials to use for authentication.
    /// - Throws: `SMTPError.serverProtocolMismatch` when `server.serverProtocol` is not `.smtp`.
    /// - Throws: `SMTPError.requiredTLSNotConfigured` when `.tls` is incorrectly specified for SMTP.
    /// - Throws: `SMTPError.serverProtocolMismatch` when OAuth2 is requested for SMTP.
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

/// Extends `Server` to allow configuration from addtional types.
extension Server {
    /// Creates a `Server` from an autoconfiguration server definition.
    ///
    /// - Parameter server: The autoconfig server description.
    /// - Returns: A configured `Server`, or `nil` when the server type is unsupported.
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

/// Extends `Server.ConnectionSecurity` to allow for autoconfiguration socket types.
extension Server.ConnectionSecurity {
    /// Creates a connection security value from an autoconfiguration socket type.
    ///
    /// - Parameters:
    ///   - socketType: The autoconfiguration socket type.
    ///   - serverProtocol: The server protocol context. When `.smtp`, `.ssl` is overridden to `.startTLS`.
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

/// Extends `Authorization` to extract a raw credential string.
private extension Authorization {
    /// The credential string to pass to protocol clients.
    ///
    /// - Returns: The password or token value, or an empty string when none.
    var rawValue: String {
        switch self {
        case .basic(_, let password): password
        case .oauth(_, let token, _): token.value
        case .none: ""
        }
    }
}

/// Extends `IMAP.ConnectionSecurity` to allow creation from other security protocols.
private extension IMAP.ConnectionSecurity {
    /// Creates an IMAP connection security value from a generic server value.
    ///
    /// - Parameter connectionSecurity: The generic server connection security.
    init(_ connectionSecurity: Server.ConnectionSecurity) {
        switch connectionSecurity {
        case .tls: self = .tls
        case .startTLS: self = .startTLS
        case .none: self = .none
        }
    }
}

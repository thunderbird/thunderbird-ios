import Autoconfiguration
import EmailAddress
import Foundation
import IMAP
import JMAP
import MIME
import SMTP

/// All supported server types enumerated.
public enum ServerProtocol: String, Codable, CaseIterable, CustomStringConvertible, Identifiable {
    case imap = "IMAP"
    case jmap = "JMAP"
    case smtp = "SMTP"

    // MARK: CustomStringConvertible
    public var description: String { rawValue }

    // MARK: Identifiable
    public var id: String { rawValue }
}

/// General purpose server model for any supported `ServerProtocol`. Stores authorization credentials locally in the [Apple keychain.](https://developer.apple.com/documentation/security/storing-keys-in-the-keychain)
public struct Server: Codable, Equatable, Hashable, Identifiable {
    public typealias ConnectionSecurity = IMAP.ConnectionSecurity

    public var serverProtocol: ServerProtocol
    public var connectionSecurity: ConnectionSecurity
    public var authenticationType: AuthenticationType
    public var username: String
    public var hostname: String
    public var port: Int

    /// Store server credentials locally in the [Apple keychain.](https://developer.apple.com/documentation/security/storing-keys-in-the-keychain)
    public var authorization: Authorization {
        set {  // Swap in keychain-specific user name
            let authorization: Authorization = Authorization(user: user, password: newValue.password)
            URLCredentialStorage.shared.set(authorization: authorization, persistence: .permanent)
        }
        get {
            guard let authorization: Authorization = URLCredentialStorage.shared.authorization(for: user) else {
                return .none
            }
            return Authorization(user: username, password: authorization.password)  // Swap out keychain-specific user name
        }
    }

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

    var user: String {  // Append unique suffix for keychain: "user@example.com IMAP:E621E1F8"
        "\(username) \(serverProtocol):\(id.uuidString(1))"
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

extension IMAPError {
    public static var serverProtocolMismatch: Self { .capabilityNotSupported("Server protocol mismatch") }
    public static var oAuth2NotSupported: Self { .capabilityNotSupported("OAuth2 not supported") }
}

extension IMAP.Server {
    public init(_ server: Server) throws {
        guard server.serverProtocol == .imap else {
            throw IMAPError.serverProtocolMismatch
        }
        guard server.authenticationType != .oAuth2 else {
            throw IMAPError.oAuth2NotSupported
        }
        self.init(
            IMAP.ConnectionSecurity(server.connectionSecurity),
            hostname: server.hostname,
            username: server.username,
            password: server.authorization.rawValue,
            port: server.port
        )
    }
}

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
        case .oauth(_, let token): token.value
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

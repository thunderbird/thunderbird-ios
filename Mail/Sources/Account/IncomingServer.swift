import Foundation

public struct IncomingServer: Codable, Identifiable {
    public enum ServerProtocol: String, Codable, CaseIterable, CustomStringConvertible {
        case imap = "IMAP"

        // MARK: CustomStringConvertible
        public var description: String { rawValue }
    }

    public let serverProtocol: ServerProtocol
    public let connectionSecurity: ConnectionSecurity
    public let authenticationType: AuthenticationType
    public let username: String
    public let hostname: String
    public let port: Int

    public var password: String? {
        URLCredentialStorage.shared.password(for: user)
    }

    public init(
        serverProtocol: ServerProtocol,
        connectionSecurity: ConnectionSecurity = .none,
        authenticationType: AuthenticationType = .none,
        username: String,
        password: String? = nil,
        hostname: String,
        port: Int? = nil,
        id: UUID = UUID()
    ) {
        self.serverProtocol = serverProtocol
        self.connectionSecurity = connectionSecurity
        self.authenticationType = authenticationType
        self.username = username
        self.hostname = hostname
        switch connectionSecurity {
        case .tls:
            self.port = port ?? 993  // Secure IMAP
        default:
            self.port = port ?? 143  // IMAP
        }
        self.id = id

        // Save password in keychain
        URLCredentialStorage.shared.set(password, for: user)
    }

    var user: String {  // Generate unique keychain user label: "user@example.com IMAP:E621E1F8"
        "\(username) \(serverProtocol):\(id.uuidString.components(separatedBy: "-")[0])"
    }

    // MARK: Identifiable
    public let id: UUID
}

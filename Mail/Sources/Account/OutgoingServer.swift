import Foundation

public struct OutgoingServer: Codable, Identifiable {
    public enum ServerProtocol: String, Codable, CaseIterable, CustomStringConvertible {
        case smtp = "SMTP"

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
        serverProtocol: ServerProtocol = .smtp,
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
        self.port = port ?? 25  // SMTP default
        self.id = id

        // Save password in keychain
        URLCredentialStorage.shared.set(password, for: user)
    }

    var user: String {  // Generate unique keychain user label: "user@example.com SMTP:E621E1F8"
        "\(username) \(serverProtocol):\(id.uuidString.components(separatedBy: "-")[0])"
    }

    // MARK: Identifiable
    public let id: UUID
}

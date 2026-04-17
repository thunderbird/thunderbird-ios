@_exported import Autoconfiguration
@_exported import EmailAddress
@_exported import IMAP
@_exported import JMAP
@_exported import MIME
@_exported import SMTP
import Foundation

public struct Account: Codable, Equatable, Hashable, Identifiable {
    public enum EmailProtocol: String, CaseIterable, CustomStringConvertible, Identifiable {
        case imap = "IMAP/SMTP"
        case jmap = "JMAP"

        // MARK: CustomStringConvertible
        public var description: String { rawValue }

        // MARK: Identifiable
        public var id: String { rawValue }
    }

    public var name: String
    public var deletePolicy: DeletePolicy
    public var identities: [EmailAddress]
    public var servers: [Server]

    public var incomingServer: Server? { server(.jmap) ?? server(.imap) ?? nil }
    public var outgoingServer: Server? { server(.jmap) ?? server(.smtp) ?? nil }

    public var emailProtocol: EmailProtocol {
        servers.map { $0.serverProtocol }.contains(.jmap) ? .jmap : .imap
    }

    public func server(_ serverProtocol: ServerProtocol) -> Server? {
        servers.filter { $0.serverProtocol == serverProtocol }.first
    }

    /// Configure an `Account` using ``Autoconfiguration.EmailProvider``.
    public init(_ emailAddress: String, provider: EmailProvider? = nil) {
        self.init(EmailAddress(emailAddress), provider: provider)
    }

    /// Configure an `Account` using ``Autoconfiguration.EmailProvider``.
    public init(_ emailAddress: EmailAddress, provider: EmailProvider? = nil) {
        self.init(
            name: emailAddress.value,
            identities: [
                emailAddress
            ],
            servers: (provider?.servers ?? []).compactMap { Server($0) },
        )
    }

    /// Configure an `Account` using memberwise initializer.
    public init(
        name: String,
        deletePolicy: DeletePolicy = .never,
        identities: [EmailAddress] = [],
        servers: [Server] = [],
        id: UUID = UUID()
    ) {
        self.name = name
        self.deletePolicy = deletePolicy
        self.identities = identities
        self.servers = servers
        self.id = id
    }

    // MARK: Identifiable
    public let id: UUID
}

extension Account {

    /// Autoconfigure a new `Account`.
    public static func autoconfig(_ emailAddress: String, isJMAPAvailable: Bool = false) async throws -> Self {
        do {
            if isJMAPAvailable, try emailAddress.host == "fastmail.com" {
                return Account(
                    name: emailAddress,
                    identities: [
                        EmailAddress(emailAddress)
                    ],
                    servers: [
                        Server(
                            .jmap,
                            connectionSecurity: .tls,
                            authenticationType: .password,
                            username: emailAddress,
                            hostname: "api.fastmail.com"
                        )
                    ]
                )
            } else {
                let config: ClientConfig = try await URLSession.shared.autoconfig(emailAddress).config
                return Account(emailAddress, provider: config.emailProvider)
            }
        } catch {
            throw AccountError.autoconfig(error)
        }
    }
}

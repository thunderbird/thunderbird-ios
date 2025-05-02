import Foundation

public struct Account: Codable, Identifiable {
    public let name: String
    public let incomingServer: IncomingServer

    public init(name: String, incomingServer: IncomingServer, id: UUID = UUID()) {
        self.name = name
        self.incomingServer = incomingServer
        self.id = id
    }

    // MARK: Identifiable
    public let id: UUID
}

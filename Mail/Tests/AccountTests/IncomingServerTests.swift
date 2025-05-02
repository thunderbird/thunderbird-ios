import Testing
import Foundation
@testable import Account

struct IncomingServerTests {
    @Test(.enabled(if: isKeychainAvailable)) func password() {
        let id: UUID = UUID()
        #expect(
            IncomingServer(
                serverProtocol: .imap,
                username: "password@example.com",
                password: "zemhu8-omdRiz-zisbov",
                hostname: "imap.example.com",
                id: id
            ).password == "zemhu8-omdRiz-zisbov")
        #expect(
            IncomingServer(
                serverProtocol: .imap,
                username: "password@example.com",
                password: nil,
                hostname: "imap.example.com",
                id: id
            ).password == nil)
    }

    @Test func user() {
        let server: IncomingServer = IncomingServer(
            serverProtocol: .imap,
            username: "user@example.com",
            password: nil,
            hostname: "imap.example.com"
        )
        let id: [String] = server.id.uuidString.components(separatedBy: "-")
        #expect(server.user == "user@example.com IMAP:\(id[0])")
    }
}

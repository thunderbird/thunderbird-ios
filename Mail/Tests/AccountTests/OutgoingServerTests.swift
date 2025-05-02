import Testing
import Foundation
@testable import Account

struct OutgoingServerTests {
    @Test(.enabled(if: isKeychainAvailable)) func password() {
        let id: UUID = UUID()
        #expect(
            OutgoingServer(
                username: "password@example.com",
                password: "gAAAAUTHtoKENb3arerJWe",
                hostname: "smtp.example.com",
                id: id
            ).password == "gAAAAUTHtoKENb3arerJWe")
        #expect(
            OutgoingServer(
                username: "password@example.com",
                password: nil,
                hostname: "smtp.example.com",
                id: id
            ).password == nil)
    }

    @Test func user() {
        let server: OutgoingServer = OutgoingServer(
            username: "user@example.com",
            password: nil,
            hostname: "smtp.example.com"
        )
        let id: [String] = server.id.uuidString.components(separatedBy: "-")
        #expect(server.user == "user@example.com SMTP:\(id[0])")
    }
}

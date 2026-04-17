@testable import Account
import Testing
import Foundation

struct AccountTests {
    @Test func incomingServer() {
        #expect(Account(name: "user@example.com", servers: [.imap, .smtp]).incomingServer?.serverProtocol == .imap)
        #expect(Account(name: "user@example.com", servers: [.jmap]).incomingServer?.serverProtocol == .jmap)
        #expect(Account(name: "user@example.com", servers: [.smtp]).incomingServer == nil)
    }

    @Test func outgoingServer() {
        #expect(Account(name: "user@example.com", servers: [.imap, .smtp]).outgoingServer?.serverProtocol == .smtp)
        #expect(Account(name: "user@example.com", servers: [.jmap]).outgoingServer?.serverProtocol == .jmap)
        #expect(Account(name: "user@example.com", servers: [.imap]).outgoingServer == nil)
    }

    @Test func server() {
        #expect(Account(name: "user@example.com", servers: [.imap, .smtp]).server(.imap)?.serverProtocol == .imap)
        #expect(Account(name: "user@example.com", servers: [.imap, .smtp]).server(.smtp)?.serverProtocol == .smtp)
        #expect(Account(name: "user@example.com", servers: [.imap, .smtp]).server(.jmap) == nil)
        #expect(Account(name: "user@example.com", servers: [.jmap]).server(.jmap)?.serverProtocol == .jmap)
        #expect(Account(name: "user@example.com", servers: [.jmap]).server(.imap) == nil)
    }
}

extension AccountTests {
    @Test func autoconfig() async throws {
        var account: Account = try await .autoconfig("example@fastmail.com", isJMAPAvailable: true)
        #expect(account.incomingServer?.serverProtocol == .jmap)
        #expect(account.incomingServer?.hostname == "autodiscover.fastmail.com")
        #expect(account.incomingServer?.port == 443)
        #expect(account.outgoingServer?.serverProtocol == .jmap)
        #expect(account.outgoingServer?.hostname == "autodiscover.fastmail.com")
        #expect(account.outgoingServer?.port == 443)
        account = try await .autoconfig("example@fastmail.com")
        #expect(account.incomingServer?.serverProtocol == .imap)
        #expect(account.incomingServer?.hostname == "imap.fastmail.com")
        #expect(account.incomingServer?.port == 993)
        #expect(account.outgoingServer?.serverProtocol == .smtp)
        #expect(account.outgoingServer?.hostname == "smtp.fastmail.com")
        #expect(account.outgoingServer?.port == 465)
    }
}

private extension Server {
    static var jmap: Self {
        Self(
            .jmap,
            connectionSecurity: .none,
            authenticationType: .none,
            username: "user",
            hostname: "jmap.example.com"
        )
    }

    static var imap: Self {
        Self(
            .imap,
            connectionSecurity: .none,
            authenticationType: .none,
            username: "user",
            hostname: "imap.example.com"
        )
    }

    static var smtp: Self {
        Self(
            .smtp,
            connectionSecurity: .none,
            authenticationType: .none,
            username: "user",
            hostname: "smtp.example.com"
        )
    }
}

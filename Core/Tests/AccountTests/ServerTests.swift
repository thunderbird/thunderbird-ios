@testable import Account
import Testing
import Foundation

struct ServerProtocolTests {
    @Test func defaultPort() {
        #expect(ServerProtocol.jmap.defaultPort == 443)
        #expect(ServerProtocol.imap.defaultPort == 993)
        #expect(ServerProtocol.smtp.defaultPort == 587)
    }
}

struct ServerTests {
    @Test(.enabled(if: isKeychainAvailable)) func authorization() throws {
        var server: Server = Server(
            .imap,
            connectionSecurity: .startTLS,
            authenticationType: .oAuth2,
            username: "user@example.com",
            hostname: "imap.example.com"
        )
        #expect(server.authorization == .none)
        server.authorization = .oauth(user: "user@example.com", token: "zemhu8-omdRiz-zisbov")
        #expect(server.user == "user@example.com IMAP:\(server.id.uuidString.components(separatedBy: "-")[0])")
        #expect(URLCredentialStorage.shared.authorization(for: server.user) != nil)
        #expect(server.authorization.user == "user@example.com")
        #expect(server.authorization.password == "zemhu8-omdRiz-zisbov")
        switch server.authorization {
        case .oauth(let user, let token):
            #expect(user == "user@example.com")
            #expect(token == "zemhu8-omdRiz-zisbov")
        default:
            throw URLError(.redirectToNonExistentLocation)
        }
        server.authorization = .basic(user: "user@example.com", password: "P@$$w0rd!")
        #expect(server.authorization.user == "user@example.com")
        #expect(server.authorization.password == "dXNlckBleGFtcGxlLmNvbTpQQCQkdzByZCE=")
        switch server.authorization {
        case .basic(let user, let password):
            #expect(user == "user@example.com")
            #expect(password == "P@$$w0rd!")
        default:
            throw URLError(.redirectToNonExistentLocation)
        }
        server.authorization = .none
        #expect(URLCredentialStorage.shared.authorization(for: server.user) == nil)
    }
}

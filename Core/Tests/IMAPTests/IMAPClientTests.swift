// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import IMAP
import MIME
import Testing

struct IMAPClientTests {

    // MARK: Mechanism not advertised
    // The first case is shared with another Thunderbird client and has a `//Source:` line linking to the test it
    // was taken from. The source test connects to a mock server whose capability list leaves the mechanism out. A
    // client that has never connected is in the same position: it has no capability that says the server supports
    // the mechanism, so it must refuse before putting a token on the wire. No connection is made by these tests.

    //Expect: Throw `capabilityNotSupported` naming `AUTH=OAUTHBEARER`.
    //Case: When signing in with OAUTHBEARER and the server hasn't advertised it.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapConnectionTest.kt#L394
    @Test func authenticate_throwsCapabilityNotSupported_whenServerHasNotAdvertisedOAuthBearer() async {
        // Arrange
        let client: IMAPClient = IMAPClient(Server(hostname: "imap.example.com"))
        let input: Authentication = .oauthbearer("user", token: "token")
        let expected: IMAPError = .capabilityNotSupported(.authenticate(.oauthBearer))

        // Act
        var actual: IMAPError?
        do {
            try await client.authenticate(input)
        } catch {
            actual = error as? IMAPError
        }

        // Assert
        #expect(actual == expected)
    }

    //Expect: Throw `capabilityNotSupported` naming `AUTH=XOAUTH2`.
    //Case: When signing in with XOAUTH2 and the server hasn't advertised it. The source has no XOAUTH2 twin of the
    //  case above, because that client only falls back to XOAUTH2 once it has seen the capability.
    @Test func authenticate_throwsCapabilityNotSupported_whenServerHasNotAdvertisedXOAuth2() async {
        // Arrange
        let client: IMAPClient = IMAPClient(Server(hostname: "imap.example.com"))
        let input: Authentication = .xoauth2("user", token: "token")
        let expected: IMAPError = .capabilityNotSupported(.authenticate(.xoauth2))

        // Act
        var actual: IMAPError?
        do {
            try await client.authenticate(input)
        } catch {
            actual = error as? IMAPError
        }

        // Assert
        #expect(actual == expected)
    }

    // MARK: Live servers
    @Test(arguments: Server.allCases(disabled: false)) func allCommands(_ server: Server) async throws {
        let client: IMAPClient = IMAPClient(server)
        try await client.connect()
        try await client.authenticate()  // Use credentials in canned `Server`

        let mailboxes: [(Mailbox, Mailbox.Status?)] = try await client.list()  // List mailboxes
        guard let inbox: Mailbox = mailboxes.filter({ $0.0.path.name.isInbox }).first?.0 else {
            throw IMAPError.unexpectedResponse("Inbox not found")
        }  // Find inbox in mailbox list
        try await client.select(mailbox: inbox.path.name)  // Select inbox

        let status = try await client.status(mailbox: inbox.path.name)
        #expect(status.messageCount != nil && status.messageCount! > 0)
        #expect(status.recentCount != nil && status.recentCount! >= 0)
        #expect(status.unseenCount != nil && status.unseenCount! >= 0)

        let messages: MessageSet = try await client.fetch()
        #expect(messages.count > 0)
        guard let number: SequenceNumber = messages.keys.sorted().reversed().first else {
            throw IMAPError.unexpectedResponse("Message not found")
        }
        let message: Message = try await client.fetch(number)
        #expect(message.body != nil)

        let mailbox: Mailbox.Name = Mailbox.Name(UUID().uuidString(2, separator: " "))  // Unique mailbox name w/ space
        let renamed: Mailbox.Name = Mailbox.Name(UUID().uuidString(1))
        try await client.create(mailbox: mailbox)
        try await client.subscribe(mailbox: mailbox)
        try await client.rename(mailbox: mailbox, to: renamed)
        try await client.unsubscribe(mailbox: renamed)  // Renamed mailbox should retain subscription
        try await client.delete(mailbox: renamed)

        do {
            try client.isSupported(.idle)
            try await client.idle()
            try await Task.sleep(for: .seconds(5.0))  // Idle
            try await client.done()
        } catch {
            switch error {
            case IMAPError.capabilityNotSupported: break
            default: throw error
            }
        }

        try await client.logout()
        try? client.disconnect()
    }
}

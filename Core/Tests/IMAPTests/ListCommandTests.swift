// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import IMAP
import NIOIMAPCore
import Testing

// `//Source:` marks a case that thunderbird-android also tests, pinned to the commit it was read at. Android asks
// `LIST` for `SPECIAL-USE` where this client asks for `SUBSCRIBED` and `STATUS`, so the cases share the rule being
// checked (no return option the server hasn't advertised) and not the option itself.
struct ListCommandTests {
    private static let subscribed: ReturnOption = .subscribed
    private static let status: ReturnOption = .statusOption([.messageCount, .recentCount, .unseenCount])

    // MARK: Return options

    //Expect: Keep no return options.
    //Case: When the server advertises neither `LIST-EXTENDED` nor `LIST-STATUS`.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/214eee3d058b16ac9f9d3bcee3bb885ab6392d97/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapStoreTest.kt#L105
    @Test func filtered_keepsNoOptions_whenServerHasNoListCapabilities() {
        // Arrange
        let input: Set<IMAP.Capability> = [.idle, .uidPlus]
        let expected: [ReturnOption] = []

        // Act
        let actual = [ReturnOption].standard.filtered(input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Keep `SUBSCRIBED` and drop `STATUS`.
    //Case: When the server advertises `LIST-EXTENDED` without `LIST-STATUS`.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/214eee3d058b16ac9f9d3bcee3bb885ab6392d97/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapStoreTest.kt#L91
    @Test func filtered_keepsOnlySubscribed_whenServerHasListExtendedOnly() {
        // Arrange
        let input: Set<IMAP.Capability> = [.listExtended]
        let expected: [ReturnOption] = [Self.subscribed]

        // Act
        let actual = [ReturnOption].standard.filtered(input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Keep both `SUBSCRIBED` and `STATUS`.
    //Case: When the server advertises `LIST-EXTENDED` and `LIST-STATUS`.
    @Test func filtered_keepsAllOptions_whenServerHasListExtendedAndListStatus() {
        // Arrange
        let input: Set<IMAP.Capability> = [.listExtended, .listStatus]
        let expected: [ReturnOption] = [Self.subscribed, Self.status]

        // Act
        let actual = [ReturnOption].standard.filtered(input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Keep no return options.
    //Case: When the server advertises `LIST-STATUS` without `LIST-EXTENDED`, which a `RETURN` clause needs.
    @Test func filtered_keepsNoOptions_whenServerHasListStatusOnly() {
        // Arrange
        let input: Set<IMAP.Capability> = [.listStatus]
        let expected: [ReturnOption] = []

        // Act
        let actual = [ReturnOption].standard.filtered(input)

        // Assert
        #expect(actual == expected)
    }

    // MARK: Command

    //Expect: Send `LIST` with no `RETURN` clause.
    //Case: When the server advertises no `LIST` capabilities.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/214eee3d058b16ac9f9d3bcee3bb885ab6392d97/mail/protocols/imap/src/test/java/com/fsck/k9/mail/store/imap/RealImapStoreTest.kt#L105
    @Test func list_sendsNoReturnClause_whenServerHasNoListCapabilities() throws {
        // Arrange
        let input: ListCommand = ListCommand(options: .standard.filtered([]), wildcard: .wildcard)
        let expected = "A01 LIST \"\" \"*\"\r\n"

        // Act
        let exchange: CommandExchange<ListCommand> = try CommandExchange(input)
        let actual = try exchange.sent()

        // Assert
        #expect(actual == expected)
    }

    //Expect: Send `LIST` asking for subscription state and message counts.
    //Case: When the server advertises `LIST-EXTENDED` and `LIST-STATUS`.
    @Test func list_sendsSubscribedAndStatusReturnOptions_whenServerHasListExtendedAndListStatus() throws {
        // Arrange
        let input: ListCommand = ListCommand(options: .standard.filtered([.listExtended, .listStatus]), wildcard: .wildcard)
        let expected = "A01 LIST \"\" \"*\" RETURN (SUBSCRIBED STATUS (MESSAGES RECENT UNSEEN))\r\n"

        // Act
        let exchange: CommandExchange<ListCommand> = try CommandExchange(input)
        let actual = try exchange.sent()

        // Assert
        #expect(actual == expected)
    }

    // MARK: Response

    //Expect: Return every mailbox, each without a status.
    //Case: When the server answers a `LIST` that had no `RETURN` clause.
    @Test func list_returnsMailboxesWithoutStatus_whenServerAnswersPlainList() throws {
        // Arrange
        let exchange: CommandExchange<ListCommand> = try CommandExchange(ListCommand(options: [], wildcard: .wildcard))
        let expected: [Listed] = [
            Listed(name: "INBOX", separator: ".", hasStatus: false),
            Listed(name: "Work", separator: ".", hasStatus: false),
            Listed(name: "Work.Q1", separator: ".", hasStatus: false)
        ]

        // Act
        try exchange.receive("* LIST () \".\" \"INBOX\"")
        try exchange.receive("* LIST () \".\" \"Work\"")
        try exchange.receive("* LIST () \".\" \"Work.Q1\"")
        try exchange.receive("A01 OK LIST completed.")
        let actual = exchange.result?.map { Listed(name: $0.0.path.name.description, separator: $0.0.path.pathSeparator, hasStatus: $0.1 != nil) }

        // Assert
        #expect(actual == expected)
    }
}

/// What a test checks about one mailbox in a `LIST` result.
private struct Listed: Equatable {
    let name: String
    let separator: Character?
    let hasStatus: Bool
}

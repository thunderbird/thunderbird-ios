@testable import Account
import Testing
import Foundation

struct MailboxPathTests {
    @Test func suggestedRole() throws {
        #expect(try IMAP.Mailbox.Path(name: "INBOX").suggestedRole == .inbox)
        #expect(try IMAP.Mailbox.Path(name: "[Gmail]/Inbox", pathSeparator: "/").suggestedRole == .inbox)
        #expect(try IMAP.Mailbox.Path(name: "Sent Mail").suggestedRole == .sent)
        #expect(try IMAP.Mailbox.Path(name: "Deleted Items").suggestedRole == .trash)
        #expect(try IMAP.Mailbox.Path(name: "junk mail").suggestedRole == .junk)
        #expect(try IMAP.Mailbox.Path(name: "Spam").suggestedRole == .junk)
        #expect(try IMAP.Mailbox.Path(name: "Trash").suggestedRole == .trash)
        #expect(try IMAP.Mailbox.Path(name: "drafts").suggestedRole == .drafts)
        #expect(try IMAP.Mailbox.Path(name: "Draft").suggestedRole == .drafts)
    }
}

struct MailboxTests {
    //Expect: Keep the separator the server reported for the mailbox.
    //Case: When the mailbox is made from an IMAP `LIST` entry.
    @Test func init_keepsPathSeparator_whenMailboxIsFromIMAPList() throws {
        // Arrange
        let input: IMAP.Mailbox = IMAP.Mailbox(path: try IMAP.Mailbox.Path(name: "Work.Q1", pathSeparator: "."), extensions: [:])
        let expected: Character? = "."

        // Act
        let actual = Mailbox((input, nil)).pathSeparator

        // Assert
        #expect(actual == expected)
    }

    //Expect: Have no separator.
    //Case: When the mailbox is made from a JMAP mailbox, which has a parent and not a path.
    @Test func init_hasNoPathSeparator_whenMailboxIsFromJMAP() {
        // Arrange
        let input: JMAP.Mailbox = JMAP.Mailbox(name: "Work")
        let expected: Character? = nil

        // Act
        let actual = Mailbox(input).pathSeparator

        // Assert
        #expect(actual == expected)
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Manages mailboxes and mailbox operations for a given Account.
@Observable
public final class MailboxManager {
    /// The Account whose mailboxes are managed.
    public let account: Account
    /// List of mailboxes for the account.
    public private(set) var mailboxes: [Mailbox] = []
    /// Most recent error encountered, if any.
    public var error: AccountError?
    /// Manages folders corresponding to mailboxes.
    public let folderManager: FolderManager

    /// Initialize with an Account.
    ///
    /// - Parameter account: The `Account` to initialize the manager with.
    public init(account: Account) {
        self.account = account
        self.folderManager = FolderManager(account: account)
    }

    /// Find a mailbox by name.
    ///
    /// - Parameter name: The name of the mailbox to be found.
    /// - Returns: A `Mailbox` with a matching name, if one exists.
    public func mailbox(_ name: String) -> Mailbox? {
        mailboxes.filter({ $0.name == name }).first
    }

    /// Find a mailbox by identifier.
    ///
    /// - Parameter id: The id of the mailbox to be found.
    /// - Returns: A `Mailbox` with a matching id, if one exists.
    public func mailbox(for id: String) -> Mailbox? {
        mailboxes.filter({ $0.id == id }).first
    }

    /// Fetch all emails in the specified mailbox.
    ///
    /// - Parameter mailbox: The mailbox for which emails will be fetched.
    /// - Returns: An array of emails returned by the service, or an empty array if there is an error.
    public func emails(in mailbox: Mailbox) async -> [Email] {
        do {
            switch account.emailProtocol {
            case .imap:
                let client: IMAPClient = try await account.imapClient
                try await client.select(mailbox: IMAP.Mailbox.Name(mailbox.name))
                let messages: MessageSet = try await client.fetch()
                return messages.keys.sorted().reversed().map { Email(messages[$0]!) }
            case .jmap:
                let client: JMAPClient = try await account.jmapClient
                let emails: [JMAP.Email] = try await client.emails(in: JMAP.Mailbox(name: mailbox.name, id: mailbox.id))
                return emails.map { Email($0) }
            }
        } catch {
            self.error = AccountError(error)
            return []
        }
    }

    /// Create a new mailbox with the given name.
    ///
    /// - Parameter name: The name of the mailbox to create.
    public func createMailbox(_ name: String) async {
        do {
            switch account.emailProtocol {
            case .imap:
                let client: IMAPClient = try await account.imapClient
                try await client.create(mailbox: IMAP.Mailbox.Name(name))
                mailboxes.append(Mailbox(name))
            case .jmap:
                let client: JMAPClient = try await account.jmapClient
                try await client.create(mailbox: JMAP.Mailbox(name: name))
            }
            await refreshMailboxes()
        } catch {
            self.error = AccountError(error)
        }
    }

    /// Rename the specified mailbox.
    ///
    /// - Parameters:
    ///   - mailbox: The `Mailbox` to apply the change to.
    ///   - name: The new name of the mailbox.
    public func rename(_ mailbox: Mailbox, to name: String) async {
        do {
            switch account.emailProtocol {
            case .imap:
                let client: IMAPClient = try await account.imapClient
                try await client.rename(mailbox: IMAP.Mailbox.Name(mailbox.name), to: IMAP.Mailbox.Name(name))
            case .jmap:
                let client: JMAPClient = try await account.jmapClient
                try await client.update(mailbox: JMAP.Mailbox(name: name, isSubscribed: mailbox.isSubscribed, id: mailbox.id))
            }
            await refreshMailboxes()
        } catch {
            self.error = AccountError(error)
        }
    }

    /// Delete the specified mailbox.
    ///
    /// - Parameter mailbox: The `Mailbox` to delete.
    public func delete(_ mailbox: Mailbox) async {
        do {
            switch account.emailProtocol {
            case .imap:
                let client: IMAPClient = try await account.imapClient
                try await client.delete(mailbox: IMAP.Mailbox.Name(mailbox.name))
            case .jmap:
                let client: JMAPClient = try await account.jmapClient
                try await client.destroy(mailbox: JMAP.Mailbox(name: mailbox.name, id: mailbox.id))
            }
            await refreshMailboxes()
        } catch {
            self.error = AccountError(error)
        }
    }

    /// Subscribe to the specified mailbox.
    ///
    /// - Parameter mailbox: The `Mailbox` to subscribe to.
    public func subscribe(_ mailbox: Mailbox) async {
        do {
            switch account.emailProtocol {
            case .imap:
                let client: IMAPClient = try await account.imapClient
                try await client.subscribe(mailbox: IMAP.Mailbox.Name(mailbox.name))
            case .jmap:
                let client: JMAPClient = try await account.jmapClient
                try await client.update(mailbox: JMAP.Mailbox(name: mailbox.name, isSubscribed: true, id: mailbox.id))
            }
            await refreshMailboxes()
        } catch {
            self.error = AccountError(error)
        }
    }

    /// Unsubscribe from the specified mailbox.
    ///
    /// - Parameter mailbox: The `Mailbox` to unsubscribe from.
    public func unsubscribe(_ mailbox: Mailbox) async {
        do {
            switch account.emailProtocol {
            case .imap:
                let client: IMAPClient = try await account.imapClient
                try await client.unsubscribe(mailbox: IMAP.Mailbox.Name(mailbox.name))
            case .jmap:
                let client: JMAPClient = try await account.jmapClient
                try await client.update(mailbox: JMAP.Mailbox(name: mailbox.name, isSubscribed: false, id: mailbox.id))
            }
            await refreshMailboxes()
        } catch {
            self.error = AccountError(error)
        }
    }

    /// Refresh the list of mailboxes from the server.
    public func refreshMailboxes() async {
        do {
            switch account.emailProtocol {
            case .imap:
                let client: IMAPClient = try await account.imapClient
                let mailboxes: [(IMAP.Mailbox, IMAP.Mailbox.Status?)] = try await client.list()
                self.mailboxes = mailboxes.map { Mailbox($0, id: self.mailbox($0.0.path.name.description)?.id) }  // Transfer UUIDs from previous list
            case .jmap:
                let client: JMAPClient = try await account.jmapClient
                let mailboxes: [JMAP.Mailbox] = try await client.mailboxes()
                self.mailboxes = mailboxes.map { Mailbox($0) }
            }

            await folderManager.refreshFolders(mailboxes: mailboxes)
        } catch {
            self.error = AccountError(error)
        }
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Manages and displays a single email message for a given account.
///
/// The manager owns the current `Email` and can refresh it from the server using the account's configured protocol.
@Observable
public final class EmailManager {
    public let account: Account
    public private(set) var email: Email?
    public var error: AccountError?

    /// Creates a manager for an email within an account.
    ///
    /// - Parameters:
    ///   - email: The initial email to manage, if any.
    ///   - account: The account used to fetch and refresh the email.
    public init(_ email: Email?, account: Account) {
        self.account = account
        self.email = email
    }

    /// Refreshes the current email from the server.
    ///
    /// Uses IMAP when the account protocol is IMAP and JMAP otherwise. Any encountered error is captured in `error`.
    ///
    /// - Returns: An asynchronous operation that completes when the refresh finishes.
    public func refreshEmail() async {
        guard let email else { return }
        do {
            switch account.emailProtocol {
            case .imap:
                guard let uid: UID = email.uid else {
                    throw IMAPError.capabilityNotSupported("UID")
                }
                let client: IMAPClient = try await account.imapClient
                let message: Message = try await client.fetch(uid: uid)
                self.email = Email(message)
            case .jmap:
                let client: JMAPClient = try await account.jmapClient
                let emails: [JMAP.Email] = try await client.emails([email.id])
                guard !emails.isEmpty else {
                    throw JMAPError.method(.invalidResultReference)
                }
                self.email = Email(emails[0])
            }
        } catch {
            self.error = AccountError(error)
        }
    }
}

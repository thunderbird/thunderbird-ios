// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import Foundation
import MIME

/// An email to send: its addresses, subject, date and MIME body. ``SMTPClient`` sends `Email`.
public struct Email: Identifiable, Sendable {
    /// The From address, also used for `MAIL FROM`.
    public let sender: EmailAddress
    /// The To addresses.
    public let recipients: [EmailAddress]
    /// The Cc addresses. They receive the email, but no `Cc` header is written; see `RequestEncoder`.
    public let copied: [EmailAddress]
    /// The Bcc addresses. They receive the email and, as Bcc should be, aren't listed in its headers.
    public let blindCopied: [EmailAddress]
    public let subject: String
    /// When the email was written. It's sent as the `Date` header and is part of the ``messageID``.
    public let date: Date
    /// The MIME body, written after the headers.
    public let body: Body

    /// The content type of the body.
    public var contentType: MIME.ContentType { body.contentType }

    /// The `Message-ID` header, made from the sender's host, the date and ``id``, so the same email always has the
    /// same ID, such as `<1762463150.A51D5B17@example.com>`.
    ///
    /// - Note: If the sender's address has no host, the ID has no `@` part, which
    ///   [RFC 5322](https://www.rfc-editor.org/rfc/rfc5322#section-3.6.4) doesn't allow.
    public var messageID: MessageID {
        MessageID(sender.host ?? "", date: date, uuid: id)
    }

    /// Make an email.
    ///
    /// - Parameters:
    ///   - sender: The From address.
    ///   - recipients: The To addresses.
    ///   - copied: The Cc addresses.
    ///   - blindCopied: The Bcc addresses.
    ///   - subject: The subject. Empty by default.
    ///   - date: When the email was written. Defaults to now.
    ///   - body: The MIME body. Defaults to an empty plain text body.
    ///   - id: The email's identity, used for the ``messageID``. Defaults to a new UUID.
    public init(
        sender: EmailAddress,
        recipients: [EmailAddress] = [],
        copied: [EmailAddress] = [],
        blindCopied: [EmailAddress] = [],
        subject: String = "",
        date: Date = Date(),
        body: Body = .empty,
        id: UUID = UUID()
    ) {
        self.sender = sender
        self.recipients = recipients
        self.copied = copied
        self.blindCopied = blindCopied
        self.subject = subject
        self.date = date
        self.body = body
        self.id = id
    }

    /// Everyone who receives the email: To, then Cc, then Bcc.
    var allRecipients: [EmailAddress] { recipients + copied + blindCopied }

    // MARK: Identifiable
    /// The email's identity, also the source of the unique part of the ``messageID``.
    public let id: UUID
}

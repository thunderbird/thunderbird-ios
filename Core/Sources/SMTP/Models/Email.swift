// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import Foundation
import MIME

/// ``SMTPClient`` sends `Email`.
public struct Email: Identifiable, Sendable {
    public let sender: EmailAddress
    public let recipients: [EmailAddress]
    public let copied: [EmailAddress]
    public let blindCopied: [EmailAddress]
    public let subject: String
    public let date: Date
    public let body: Body

    public var contentType: MIME.ContentType { body.contentType }

    public var messageID: MessageID {
        MessageID(sender.host ?? "", date: date, uuid: id)
    }

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

    var allRecipients: [EmailAddress] { recipients + copied + blindCopied }

    // MARK: Identifiable
    public let id: UUID
}

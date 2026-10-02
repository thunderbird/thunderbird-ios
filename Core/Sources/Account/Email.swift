// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import Foundation
import IMAP
import JMAP
import MIME

/// Common `Email` model represents and losslessly converts to and from both ``IMAP.Message`` and ``JMAP.Email``
public struct Email: CustomStringConvertible, Identifiable, Sendable {
    public var from: [EmailAddressProtocol]
    public var sender: [EmailAddressProtocol]
    public var replyTo: [EmailAddressProtocol]
    public var to: [EmailAddressProtocol]
    public var bcc: [EmailAddressProtocol]
    public var cc: [EmailAddressProtocol]
    public var universalFlags: Set<UniversalFlag>
    public let received: Date?  // IMAP internal message date
    public let sent: Date?  // IMAP envelope date
    public let messageID: [String]
    public let threadID: [String]
    public let inReplyTo: [String]
    public var subject: String?
    public var body: EmailBody?
    public let blobID: String?
    public let uid: UID?

    public init(
        from: [EmailAddressProtocol] = [],
        sender: [EmailAddressProtocol] = [],
        replyTo: [EmailAddressProtocol] = [],
        to: [EmailAddressProtocol] = [],
        bcc: [EmailAddressProtocol] = [],
        cc: [EmailAddressProtocol] = [],
        received: Date? = nil,
        sent: Date? = nil,
        messageID: [String] = [],
        threadID: [String] = [],
        inReplyTo: [String] = [],
        subject: String? = nil,
        body: EmailBody? = nil,
        blobID: String? = nil,
        uid: UID? = nil,
        id: String? = nil,
        universalFlags: Set<UniversalFlag> = []
    ) {
        self.from = from
        self.sender = sender
        self.replyTo = replyTo
        self.to = to
        self.bcc = bcc
        self.cc = cc
        self.received = received
        self.sent = sent
        self.messageID = messageID
        self.threadID = threadID
        self.inReplyTo = inReplyTo
        self.subject = subject
        self.body = body
        self.blobID = blobID
        self.uid = uid
        self.id = id ?? UUID().uuidString(1)
        self.universalFlags = universalFlags
    }

    // MARK: CustomStringConvertible
    public var description: String { messageID.first ?? id }

    // MARK: Identifiable
    public let id: String  // IMAP message ID
}

extension Email {
    // Decode Gmail message ID, if present
    var gmailMessageID: UInt64? {
        guard let id: UInt64 = UInt64(messageID.last ?? ""), id > .gmailIDFloor else {
            return nil
        }
        return id
    }

    // Decode Gmail thread ID, if present
    var gmailThreadID: UInt64? {
        guard let id: UInt64 = UInt64(threadID.last ?? ""), id > .gmailIDFloor else {
            return nil
        }
        return id
    }

    // Go back and forth between local Universal Flags and IMAP and JMAP representations
    static func imapFlagsToUniversal(flags: Set<Flag>) -> Set<UniversalFlag> {
        return Set(flags.compactMap { imapToUniversalMap[$0] })
    }

    static func jmapKeywordsToUniversal(keywords: [String: Bool]) -> Set<UniversalFlag> {
        return Set(keywords.keys.compactMap { jmapToUniversalFlagMap[$0] })
    }

    static func universalFlagsToImap(flags: Set<UniversalFlag>) -> [Flag] {
        var imapFlags: [Flag] = flags.compactMap { imapFlagMap[$0] ?? "" }
        return imapFlags
    }

    static func universalFlagsToJmap(flags: Set<UniversalFlag>) -> [String: Bool] {
        return Dictionary(uniqueKeysWithValues: flags.compactMap { jmapFlagMap[$0] }.map { ($0, true) })
    }

    // Map from IMAP message
    init(_ message: IMAP.Message) {
        self.init(
            from: message.envelope.from,
            sender: message.envelope.sender,
            replyTo: message.envelope.reply,
            to: message.envelope.to,
            bcc: message.envelope.bcc,
            cc: message.envelope.cc,
            received: message.internalDate,  // IMAP internal message date
            sent: message.envelope.date?.date,  // IMAP envelope date; forget sender time zone
            messageID: message.messageIDs,
            threadID: message.threadIDs,
            inReplyTo: message.inReplyTo,
            subject: message.envelope.subject,
            body: try? EmailBody(body: message.body),
            uid: message.uid,
            id: message.emailID ?? message.gmailID,
            universalFlags: Email.imapFlagsToUniversal(flags: message.flags)
        )
    }

    // Map from JMAP email
    init(_ email: JMAP.Email) {
        self.init(
            from: email.from ?? [],
            sender: email.sender ?? [],
            replyTo: email.replyTo ?? [],
            to: email.to ?? [],
            bcc: email.bcc ?? [],
            cc: email.cc ?? [],
            received: email.receivedAt,
            sent: email.sentAt,
            messageID: email.messageID ?? [],
            threadID: [email.threadID],
            inReplyTo: email.inReplyTo ?? [],
            subject: email.subject,
            body: try? EmailBody(email: email),
            blobID: email.blobID,
            id: email.id,
            universalFlags: Email.jmapKeywordsToUniversal(keywords: email.keywords)
        )
    }
}

// MARK: - EmailAddressProtocol array conversion methods
extension Email {
    // A convenience function that converts an array of `EmailAddressProtocol` to an array of strings.
    public func addressesStringArray(_ a: [EmailAddressProtocol]) -> [String] {
        a.flatMap { $0.addresses.map { $0.value } }
    }

    // A convenience function that combines all of the addresses into a single comma separated string.
    public func commaSeparatedAddresses(_ a: [EmailAddressProtocol]) -> String {
        a.flatMap { $0.addresses.map { $0.value } }.joined(separator: ", ")
    }

    public var toStringArray: [String] { addressesStringArray(to) }
    public var replyToStringArray: [String] { addressesStringArray(replyTo) }
    public var ccStringArray: [String] { addressesStringArray(cc) }
    public var bccStringArray: [String] { addressesStringArray(bcc) }
}

// MARK: - Convenience methods for reassigning senders/receivers
extension Email {
    public func asReply(all: Bool) -> Email {
        var newEmail = self
        newEmail.to = from

        if !all {
            newEmail.cc = []
            newEmail.bcc = []
        }

        return newEmail
    }
}

// MARK: - Convenience for unified flag setting
extension Email {
    public enum UniversalFlag: String, Sendable {
        case seen = "seen"
        case flagged = "flagged"
        case answered = "answered"
        case draft = "draft"
        case deleted = "deleted"
        case unknown = "unknown"
    }

    static let imapFlagMap: [UniversalFlag: Flag] = [
        .seen: Flag.seen,
        .answered: Flag.answered,
        .deleted: Flag.deleted,
        .draft: Flag.draft,
        .flagged: Flag.flagged
    ]

    static let jmapFlagMap: [UniversalFlag: String] = [
        .seen: "$seen",
        .answered: "$answered",
        .draft: "$draft",
        .flagged: "$flagged"
    ]

    static let imapToUniversalMap: [Flag: UniversalFlag] = [
        Flag.seen: .seen,
        Flag.answered: .answered,
        Flag.deleted: .deleted,
        Flag.draft: .draft,
        Flag.flagged: .flagged
    ]

    static let jmapToUniversalFlagMap: [String: UniversalFlag] = [
        "$seen": .seen,
        "$answered": .answered,
        "$draft": .draft,
        "$flagged": .flagged
    ]

    public func setFlag(flag: UniversalFlag, setToTrue: Bool) {
        var email = self
        if setToTrue {
            email.universalFlags.insert(flag)
        } else {
            email.universalFlags.remove(flag)
        }
        //push update to mailbox
    }
}

extension IMAP.Message {

    // Use `gmailMessageID` as ID string, if present
    var gmailID: String? { gmailMessageID != nil ? "\(gmailMessageID!)" : nil }

    // Collect available message IDs, plain and/or Gmail flavored
    var messageIDs: [String] {
        var ids: [String] = []
        if let id: String = envelope.messageID {
            ids.append(id)
        }
        if let id: UInt64 = gmailMessageID {
            ids.append("\(id)")
        }
        return ids
    }

    // Collect available thread IDs, plain and/or Gmail flavored
    var threadIDs: [String] {
        var ids: [String] = []
        if let id: String = threadID {
            ids.append(id)
        }
        if let id: UInt64 = gmailThreadID {
            ids.append("\(id)")
        }
        return ids
    }

    var inReplyTo: [String] {
        var ids: [String] = []
        if let id: String = envelope.inReplyTo {
            ids.append(id)
        }
        return ids
    }

    // Map back to IMAP message
    init(_ email: Email) {
        self.init(
            body: nil,  // email.body,
            emailID: email.id,
            envelope: Envelope(
                subject: email.subject,
                date: email.sent?.internetMessageDate,
                from: email.from,
                sender: email.sender,
                reply: email.replyTo,
                to: email.to,
                cc: email.cc,
                bcc: email.bcc,
                inReplyTo: email.inReplyTo.first,
                messageID: email.messageID.first
            ),
            flags: Email.universalFlagsToImap(flags: email.universalFlags),
            gmailLabels: [],  // TODO: incorporate gmailLabels
            gmailMessageID: email.gmailMessageID,
            gmailThreadID: email.gmailThreadID,
            internalDate: email.received,
            threadID: email.threadID.first,
            uid: email.uid
        )
    }
}

extension JMAP.Email {

    // Map back to JMAP email
    init(_ email: Email) {
        self.init(
            blobID: email.blobID ?? "",
            threadID: email.threadID.first ?? "",
            mailboxIDs: [:],  // TODO: JMAP mailbox IDs not carried
            keywords: Email.universalFlagsToJmap(flags: email.universalFlags),
            size: 0,
            receivedAt: email.received,
            sentAt: email.sent,
            messageID: !email.messageID.isEmpty ? email.messageID : nil,
            inReplyTo: !email.inReplyTo.isEmpty ? email.inReplyTo : nil,
            references: nil,
            sender: !email.sender.isEmpty ? email.sender : nil,
            from: !email.from.isEmpty ? email.from : nil,
            replyTo: !email.replyTo.isEmpty ? email.replyTo : nil,
            to: !email.to.isEmpty ? email.to : nil,
            cc: !email.cc.isEmpty ? email.cc : nil,
            bcc: !email.bcc.isEmpty ? email.bcc : nil,
            subject: email.subject,
            bodyStructure: nil,  // TODO: JMAP body structure encoding not implemented
            textBody: [],
            htmlBody: [],
            attachments: [],  // TODO: JMAP attachments not implemented
            hasAttachment: false,
            preview: nil,  // // TODO: JMAP preview not implemented
            id: email.id
        )
    }
}

extension Date {
    var internetMessageDate: InternetMessageDate { InternetMessageDate(self) }
}

private extension UInt64 {
    static let gmailIDFloor: Self = 1_000_000_000_000
}

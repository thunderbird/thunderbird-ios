// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import Foundation
import IMAP
import JMAP
import MIME

/// A unified model representing an email message, providing a lossless mapping between IMAP and JMAP formats.
/// This model supports conversions from both IMAP messages and JMAP emails, preserving all relevant data.
///
/// This struct acts as the central representation for emails within the system, ensuring consistency
/// and interoperability between different email protocols and their respective data structures.
public struct Email: CustomStringConvertible, Identifiable, Sendable {
    public var from: [EmailAddressProtocol]
    public var sender: [EmailAddressProtocol]
    public var replyTo: [EmailAddressProtocol]
    public var to: [EmailAddressProtocol]
    public var bcc: [EmailAddressProtocol]
    public var cc: [EmailAddressProtocol]
    public let received: Date?  // IMAP internal message date
    public let sent: Date?  // IMAP envelope date
    public let messageID: [String]
    public let threadID: [String]
    public let inReplyTo: [String]
    public var subject: String?
    public var body: EmailBody?
    public var flags: Set<Flag>
    public var labels: Set<GmailLabel>
    public let blobID: String?
    public let uid: UID?
    public let id: String  // IMAP message ID

    /// Creates a new Email instance with the specified properties.
    ///
    /// - Parameters:
    ///   - from: Email addresses in the "from" field.
    ///   - sender: Email addresses in the "sender" field.
    ///   - replyTo: Email addresses in the "replyTo" field.
    ///   - to: Email addresses in the "to" field.
    ///   - bcc: Email addresses in the "bcc" field.
    ///   - cc: Email addresses in the "cc" field.
    ///   - received: The date the email was received.
    ///   - sent: The date the email was sent.
    ///   - messageID: The message id associated with the email. Used to link emails together in threads.
    ///   - threadID: The id of the thread associated with the email.
    ///   - inReplyTo: The id of the message this email is in response to.
    ///   - subject: The email's subject.
    ///   - body: The body content of the email.
    ///   - flags: The set of flags associated with the email.
    ///   - labels: The set of labels associated with the email.
    ///   - blobid: The id of the blob associated with the email
    ///   - uid: The id of the user associated with the email.
    ///   - id: The unique identifier for the email. If none is provided, one will be generated.
    ///
    /// - Discussion:
    /// The `id` uniquely identifies the email within the system. If not provided, it will be generated to ensure uniqueness.
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
        flags: Set<Flag> = [],
        labels: Set<GmailLabel> = [],
        blobID: String? = nil,
        uid: UID? = nil,
        id: String? = nil
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
        self.flags = flags
        self.labels = labels
        self.blobID = blobID
        self.uid = uid
        self.id = id ?? UUID().uuidString(1)
    }

    /// Required for `CustomStringConvertible` conformance.
    public var description: String { messageID.first ?? id }
}

/// Extends `Email` with computed properties for GMail id's.
extension Email {
    /// Returns the Gmail message ID extracted from the email's last message id.
    ///
    /// - Returns: A UInt64 representing the Gmail message ID, or nil if not found.
    var gmailMessageID: UInt64? {
        guard let id: UInt64 = UInt64(messageID.last ?? ""), id > .gmailIDFloor else {
            return nil
        }
        return id
    }

    /// Returns the Gmail thread ID extracted from the email's last thread id.
    ///
    /// - Returns: A UInt64 representing the Gmail thread ID, or nil if not found.
    var gmailThreadID: UInt64? {
        guard let id: UInt64 = UInt64(threadID.last ?? ""), id > .gmailIDFloor else {
            return nil
        }
        return id
    }
}

/// Extends `Email` with convenience initializers from IMAP and JMAP.
extension Email {
    /// Initializes an Email instance from an IMAP message.
    ///
    /// - Parameter message: The IMAP message to convert.
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
            flags: message.flags,
            labels: message.gmailLabels,
            uid: message.uid,
            id: message.emailID ?? message.gmailID
        )
    }

    /// Initializes an Email instance from a JMAP email.
    ///
    /// - Parameter email: The JMAP email to convert.
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
            id: email.id
        )
    }
}

/// Extends `Email` to assist with converting `EmailAddressProtocol` arrays for ease of display.
extension Email {
    /// Converts an array of `EmailAddressProtocol`s to an array of strings.
    ///
    /// - Parameter a: The array of `EmailAddressProtocol` to convert.
    /// - Returns: an array of `String`.
    public func addressesStringArray(_ a: [EmailAddressProtocol]) -> [String] {
        a.flatMap { $0.addresses.map { $0.value } }
    }

    /// Converts an array of `EmailAddressProtocol`s to a comma separated string.
    ///
    /// - Parameter a: The array of `EmailAddressProtocol` to convert.
    /// - Returns: a comma separated `String`.
    public func commaSeparatedAddresses(_ a: [EmailAddressProtocol]) -> String {
        a.flatMap { $0.addresses.map { $0.value } }.joined(separator: ", ")
    }

    public var toStringArray: [String] { addressesStringArray(to) }
    public var replyToStringArray: [String] { addressesStringArray(replyTo) }
    public var ccStringArray: [String] { addressesStringArray(cc) }
    public var bccStringArray: [String] { addressesStringArray(bcc) }
}

/// Extends `Email` to support quickly configuring replies.
extension Email {
    /// Creates an email representing a reply to the current email.
    ///
    /// - Parameter all: If true, includes all recipients; otherwise includes necessary recipients only.
    /// - Returns: A new `Email` instance configured as a reply.
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

// MARK: - Flag recognition computed properties

/// Represents the types of IMAP flags that can be associated with an email.
/// https://datatracker.ietf.org/doc/html/rfc9051#name-flags-message-attribute
public enum FlagType: String, Sendable {
    case answered = "answered"
    case deleted = "deleted"
    case draft = "draft"
    case flagged = "flagged"
    case recent = "recent"
    case seen = "seen"
}

/// Represents the types of GMail labels that can be associated with an email.
/// https://developers.google.com/workspace/gmail/api/guides/labels
public enum LabelType: String, Sendable {
    case inbox = "\\inbox"
    case spam = "\\spam"
    case trash = "\\trash"
    case unread = "\\unread"
    case starred = "\\starred"
    case important = "\\important"
    case sent = "\\sent"
    case draft = "\\draft"
    case personal = "\\category_personal"
    case social = "\\category_social"
    case promotions = "\\category_promotions"
    case updates = "\\category_updates"
    case forums = "\\category_forums"
}

extension Email {
    /// Returns whether the email has the specified flag.
    ///
    /// - Parameter flag: The flag to check.
    /// - Returns: `true` if the email has the flag; otherwise, `false`.
    public func hasFlag(_ flag: FlagType) -> Bool {
        switch flag {
        case .answered:
            return flags.contains(.answered)
        case .deleted:
            return flags.contains(.deleted)
        case .draft:
            return flags.contains(.draft)
        case .flagged:
            return flags.contains(.flagged)
        case .seen:
            return flags.contains(.seen)
        default:
            return false
        }
    }

    /// Returns whether the email has the specified label.
    ///
    /// - Parameter label: The label to check.
    /// - Returns: `true` if the email has the label; otherwise, `false`.
    public func hasLabel(_ gmailLabel: LabelType) -> Bool {
        for label in labels {
            if label.description.lowercased() == gmailLabel.rawValue {
                return true
            }
        }

        return false
    }
}

/// Extends `IMAP.Message` with computed properties for parsing ID's from differing services.
extension IMAP.Message {
    /// Retrieves the Gmail message ID associated with the IMAP message.
    ///
    /// - Returns: A UInt64 representing the Gmail message ID, if available.
    var gmailID: String? { gmailMessageID != nil ? "\(gmailMessageID!)" : nil }

    /// Returns the list of message IDs associated with the IMAP message.
    /// Can differ between providers.
    ///
    /// - Returns: An array of message IDs.
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

    /// Returns the list of thread IDs associated with the IMAP message.
    /// /// Can differ between providers.
    ///
    /// - Returns: An array of thread IDs.
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

    /// Returns an array of message IDs that this IMAP message is in reply to.
    ///
    /// - Returns: An array of message IDs, if available.
    var inReplyTo: [String] {
        var ids: [String] = []
        if let id: String = envelope.inReplyTo {
            ids.append(id)
        }
        return ids
    }
}

/// Extends `IMAP.Message` to enable converting from a generic local `Email` to an `IMAP` style `Message`.
extension IMAP.Message {
    /// Initializes an IMAP.Message from an Email instance.
    ///
    /// - Parameter email: The Email instance to convert.
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
            flags: [],
            gmailLabels: [],
            gmailMessageID: email.gmailMessageID,
            gmailThreadID: email.gmailThreadID,
            internalDate: email.received,
            threadID: email.threadID.first,
            uid: email.uid
        )
    }
}

/// Extends `JMAP.Email` to enable converting from a generic local `Email` to an `JMAP` style `Email`.
extension JMAP.Email {
    /// Initializes a JMAP.Email from an Email instance.
    ///
    /// - Parameter email: The Email instance to convert.
    init(_ email: Email) {
        self.init(
            blobID: email.blobID ?? "",
            threadID: email.threadID.first ?? "",
            mailboxIDs: [:],  // TODO: JMAP mailbox IDs not carried
            keywords: [:],  // TODO: JMAP keywords not implemented
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

/// Extends `Date` with a convenience variable to reading internet message dates.
extension Date {
    /// Converts the date into an Internet Message date string format.
    ///
    /// - Returns: A formatted date string suitable for Internet Message headers.
    var internetMessageDate: InternetMessageDate { InternetMessageDate(self) }
}

/// Extends `UInt64` to assist with identifying GMail message ideas.
private extension UInt64 {
    /// The floor value for Gmail message IDs, representing a threshold for valid IDs.
    static let gmailIDFloor: Self = 1_000_000_000_000
}

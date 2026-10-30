// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import Foundation
import MIME
import NIOIMAPCore

/// This is a bridging data class that converts the IMAP library’s NIOIMAPCore.Envelope into the Domain Model - including decoding the subject and parsing the date.
///
/// Its role in the app is:
///
/// 1. Standard IMAP fetches request the envelope.
/// 2. The result is stored on an IMAP.Message.
/// 3. The account layer uses it to populate an Email’s subject, addresses, and sent date in Email.swift (Core/Sources/Account/Email.swift:96)
///
/// It contains metadata only; the message body is stored separately.
///
/// “Envelope” is the IMAP protocol’s name for a structured summary of a message’s headers. This Swift type follows that terminology.
///
/// The analogy is a physical letter: the envelope tells you who sent it and who it’s addressed to, while the contents are separate.
/// IMAP stretches that analogy by including the subject, date, and message IDs too.

public struct Envelope: Sendable {
    public let subject: String?
    public let date: InternetMessageDate?
    public let from: [EmailAddressProtocol]
    public let sender: [EmailAddressProtocol]
    public let reply: [EmailAddressProtocol]
    public let to: [EmailAddressProtocol]
    public let cc: [EmailAddressProtocol]
    public let bcc: [EmailAddressProtocol]
    public let inReplyTo: String?
    public let messageID: String?

    public init(
        subject: String? = nil,
        date: InternetMessageDate? = nil,
        from: [EmailAddressProtocol] = [],
        sender: [EmailAddressProtocol] = [],
        reply: [EmailAddressProtocol] = [],
        to: [EmailAddressProtocol] = [],
        cc: [EmailAddressProtocol] = [],
        bcc: [EmailAddressProtocol] = [],
        inReplyTo: String? = nil,
        messageID: String? = nil,
    ) {
        self.subject = subject
        self.date = date
        self.from = from
        self.sender = sender
        self.reply = reply
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.inReplyTo = inReplyTo
        self.messageID = messageID
    }

    init(_ envelope: NIOIMAPCore.Envelope) {
        subject = try? envelope.subject?.readableBytesView.description.headerDecoded()
        from = envelope.from.addresses
        sender = envelope.sender.addresses
        reply = envelope.reply.addresses
        to = envelope.to.addresses
        cc = envelope.cc.addresses
        bcc = envelope.bcc.addresses
        inReplyTo = String(envelope.inReplyTo)
        messageID = String(envelope.messageID)
        date = try? InternetMessageDate(internetMessageDate: envelope.date)
    }
}

// MARK: - String Extension
extension String {
    init?(_ messageID: NIOIMAPCore.MessageID?) {
        guard let messageID else {
            return nil
        }
        self.init(messageID)
    }
}

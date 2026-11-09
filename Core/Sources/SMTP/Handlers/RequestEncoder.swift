// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import Foundation
import MIME
import NIOCore

enum Request {
    case hello(String)
    case startTLS
    case authLogin
    case authUser(String)
    case authPassword(String)
    case mailFrom(EmailAddress)
    case recipient(EmailAddress)
    case data
    case transferData(Email)
    case quit
}

struct RequestEncoder: MessageToByteEncoder {

    // MARK: MessageToByteEncoder
    typealias OutboundIn = Request

    func encode(data: OutboundIn, out: inout ByteBuffer) throws {
        switch data {
        case .hello(let hostname):
            out.writeString("EHLO \(hostname)")
        case .startTLS:
            out.writeString("STARTTLS")
        case .authLogin:
            out.writeString("AUTH LOGIN")
        case .authUser(let value), .authPassword(let value):
            out.writeBytes((value.data(using: .utf8) ?? Data()).base64EncodedData())
        case .mailFrom(let emailAddress):
            out.writeString("MAIL FROM:<\(emailAddress.value)>")
        case .recipient(let emailAddress):
            out.writeString("RCPT TO:<\(emailAddress.value)>")
        case .data:
            out.writeString("DATA")
        case .transferData(let email):
            out.writeString("From: \(email.sender)\(crlf)")
            out.writeString("To: \(email.recipients.map { $0.description }.joined(separator: " "))\(crlf)")
            out.writeString("Date: \(email.date.rfc822Format())\(crlf)")
            out.writeString("Message-ID: \(email.messageID)\(crlf)")
            out.writeString("Subject: \(email.subject)\(crlf)")
            out.writeBytes(email.body.rawValue)
            out.writeString("\(crlf).")
        case .quit:
            out.writeString("QUIT")
        }
        out.writeString(crlf)
    }
}

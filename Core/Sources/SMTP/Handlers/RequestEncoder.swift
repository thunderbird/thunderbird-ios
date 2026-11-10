// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import Foundation
import MIME
import NIOCore

/// The commands the client sends, in the order a send uses them.
enum Request {
    /// `EHLO`, the greeting, with a host name.
    ///
    /// ``SendHandler`` passes the server's host name, but
    /// [RFC 5321](https://www.rfc-editor.org/rfc/rfc5321#section-4.1.1.1) expects the client's own domain or address.
    // TODO: Send the client's own host name, or an address literal, in `EHLO`.
    case hello(String)
    /// `STARTTLS`, which asks to upgrade the connection to TLS.
    case startTLS
    /// `AUTH LOGIN`, which starts signing in with a user name and password.
    ///
    /// - Important: It's the only sign-in method, so accounts that use OAuth2, which need `XOAUTH2` or `OAUTHBEARER`,
    ///   can't send. The Account module also refuses OAuth2 for SMTP.
    // TODO: Support `XOAUTH2` or `OAUTHBEARER`, and `AUTH PLAIN`, choosing from the methods the server lists after
    // `EHLO`.
    case authLogin
    /// The user name for `AUTH LOGIN`, written as base64.
    case authUser(String)
    /// The password for `AUTH LOGIN`, written as base64.
    case authPassword(String)
    /// `MAIL FROM` with the sender's address.
    case mailFrom(EmailAddress)
    /// `RCPT TO` with one recipient's address.
    case recipient(EmailAddress)
    /// `DATA`, which asks to start sending the email.
    case data
    /// The email itself: its headers, its body, and the line with a single `.` that ends it.
    case transferData(Email)
    /// `QUIT`, which ends the session.
    case quit
}

/// Writes each ``Request`` as the line of text SMTP sends, ending with CRLF.
struct RequestEncoder: MessageToByteEncoder {

    // MARK: MessageToByteEncoder
    typealias OutboundIn = Request

    /// Write one command.
    ///
    /// For ``Request/transferData(_:)`` the email is written as `From`, `To`, `Date`, `Message-ID` and `Subject`
    /// headers, then the body's own headers and content, then the line with a single `.`.
    ///
    /// - Parameters:
    ///   - data: The command to write.
    ///   - out: The buffer to write it to.
    /// - Important: Several things about the email text don't follow the standards yet:
    ///   - `To` addresses are separated by spaces, but [RFC 5322](https://www.rfc-editor.org/rfc/rfc5322#section-3.4)
    ///     needs commas.
    ///   - Cc addresses receive the email, but no `Cc` header is written, so nobody can see who was copied.
    ///   - Body lines that start with `.` aren't doubled
    ///     ([RFC 5321 section 4.5.2](https://www.rfc-editor.org/rfc/rfc5321#section-4.5.2)). A line that is just `.`
    ///     ends the email early, and the server removes the leading `.` from other lines.
    ///   - Names and subjects that aren't ASCII are written as raw UTF-8, not as
    ///     [RFC 2047](https://www.rfc-editor.org/rfc/rfc2047) encoded words.
    ///   - A line break in the subject starts a new header.
    ///   - There is no `MIME-Version` header for a single-part body.
    ///   - The `Date` header follows the device's locale and calendar (#626).
    // TODO: Dot-stuff the body (#639), separate `To` addresses with commas (#641), write a `Cc` header (#642), encode
    // non-ASCII names and the subject with `headerEncoded()` (#643), remove line breaks from header values (#644), and
    // always write `MIME-Version`.
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

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore
@testable import SMTP
import Testing

struct RequestEncoderTests {
    // RFC 5322 separates the addresses in an address list with commas (#641). They used to be separated with spaces.
    @Test func encodeTransferData_separatesToAddressesWithCommas() throws {
        #expect(try toHeader(.example) == "To: Recipient Name <recipient@example.com>, no.name@exmaple.com")
        #expect(try toHeader(Email(sender: "sender@example.com", recipients: ["recipient@example.com"])) == "To: recipient@example.com")
    }

    private func toHeader(_ email: Email) throws -> String? {
        var buffer: ByteBuffer = ByteBuffer()
        try RequestEncoder().encode(data: .transferData(email), out: &buffer)
        return buffer.readString(length: buffer.readableBytes)?.components(separatedBy: "\r\n").first { $0.hasPrefix("To: ") }
    }

    @Test func encode() throws {
        var buffer: ByteBuffer = ByteBuffer()
        try RequestEncoder().encode(data: .hello("smtp.example.com"), out: &buffer)
        #expect(buffer.readString(length: buffer.readableBytes) == "EHLO smtp.example.com\r\n")
        try RequestEncoder().encode(data: .startTLS, out: &buffer)
        #expect(buffer.readString(length: buffer.readableBytes) == "STARTTLS\r\n")
        try RequestEncoder().encode(data: .authLogin, out: &buffer)
        #expect(buffer.readString(length: buffer.readableBytes) == "AUTH LOGIN\r\n")
        try RequestEncoder().encode(data: .authUser("user@example.com"), out: &buffer)
        #expect(buffer.readString(length: buffer.readableBytes) == "dXNlckBleGFtcGxlLmNvbQ==\r\n")
        try RequestEncoder().encode(data: .authPassword("P@s$W0rd"), out: &buffer)
        #expect(buffer.readString(length: buffer.readableBytes) == "UEBzJFcwcmQ=\r\n")
        try RequestEncoder().encode(data: .mailFrom("Sender Name <sender@example.com>"), out: &buffer)
        #expect(buffer.readString(length: buffer.readableBytes) == "MAIL FROM:<sender@example.com>\r\n")
        try RequestEncoder().encode(data: .recipient("Recipient Name <recipient@example.com>"), out: &buffer)
        #expect(buffer.readString(length: buffer.readableBytes) == "RCPT TO:<recipient@example.com>\r\n")
        try RequestEncoder().encode(data: .data, out: &buffer)
        #expect(buffer.readString(length: buffer.readableBytes) == "DATA\r\n")
        try RequestEncoder().encode(data: .transferData(.example), out: &buffer)
        #expect(buffer.readString(length: buffer.readableBytes) == example)
        try RequestEncoder().encode(data: .quit, out: &buffer)
        #expect(buffer.readString(length: buffer.readableBytes) == "QUIT\r\n")
    }
}

// swift-format-ignore
private let example: String = """
From: Sender Name <sender@example.com>\r
To: Recipient Name <recipient@example.com> no.name@exmaple.com\r
Date: Thu, 06 Nov 2025 21:05:50 +0000\r
Message-ID: <1762463150.A51D5B17@example.com>\r
Subject: Example email subject\r
Content-Type: text/plain; charset="US-ASCII"\r
\r
Plain text body content (using only US-ASCII characters)\r
\r
.\r

"""

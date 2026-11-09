// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import Foundation
import MIME
@testable import SMTP
import Testing

struct SMTPClientTests {
    @Test(arguments: Server.allCases(disabled: false)) func send(server: Server) async throws {
        try await SMTPClient(server).send(.email(EmailAddress(server.username)))
    }

    // An email with no To, Cc or Bcc recipients used to return as if it had been sent (#640). The server host doesn't
    // exist, so the test can't pass by connecting; it passes only if the client refuses before connecting.
    @Test func send_throwsRecipientNotFound_whenEmailHasNoRecipients() async {
        let client: SMTPClient = SMTPClient(Server(hostname: "smtp.invalid", username: "user", password: "pass"), logger: nil)
        await #expect(throws: SMTPError.emailRecipientNotFound) {
            try await client.send(Email(sender: "sender@example.com"))
        }
        await #expect(throws: SMTPError.emailRecipientNotFound) {
            try await client.send([Email(sender: "sender@example.com")])
        }
    }
}

private extension Email {
    static func email(_ address: EmailAddress) -> Self {
        Self(
            sender: address,
            recipients: [
                address  // Send to self
            ],
            subject: "Example email subject",
            body: try! Body(
                part:
                    Part(data: "For a brief period of time, email body contents were made of plain, ASCII text only :)".data(using: .ascii)!, contentType: .text(.plain, .ascii))
            ),
            id: UUID(uuidString: "A51D5B17-CA61-4FF1-A4A8-C717289B8F9E")!
        )
    }
}

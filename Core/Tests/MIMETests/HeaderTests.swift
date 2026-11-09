// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import MIME
import Testing

struct HeaderTests {
    @Test func nameValueInit() throws {
        #expect(try Header(.contentTransferEncoding, "quoted-printable").value == "quoted-printable")
        #expect(throws: MIMEError.self) {
            try Header(.contentTransferEncoding, "quotëd-printable")  // Value not ASCII
        }
    }

    // MARK: RawRepresentable
    @Test func rawValue() throws {
        #expect(try Header(.contentType, "text/html").rawValue == "Content-Type: text/html")
        #expect(Header.mimeVersion.rawValue == "MIME-Version: 1.0")
    }

    @Test func rawValueInit() throws {
        #expect(Header(rawValue: "Content-Transfer-Encoding: quoted-printable") == (try Header(.contentTransferEncoding, "quoted-printable")))
        #expect(Header(rawValue: "Content-Transfer-Encoding: quotëd-printable") == nil)
        #expect(Header(rawValue: "MIME-Version: 1.0") == .mimeVersion)
    }
}

extension HeaderTests {
    @Test func rawValueInitUnknownName() {
        #expect(Header(rawValue: "X-Mailer: Thunderbird") == nil)
    }
}

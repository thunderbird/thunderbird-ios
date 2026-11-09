// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import MIME
import Testing

struct RFC822DateFormatterTests {
    @Test func dateFormat() {
        #expect(RFC822DateFormatter().dateFormat == "EEE, dd MMM yyyy HH:mm:ss Z")
    }

    @Test func string() {
        let formatter: RFC822DateFormatter = RFC822DateFormatter()
        #expect(formatter.string(from: Date(timeIntervalSince1970: 247133640.0), TimeZone(secondsFromGMT: -5 * 3600)!) == "Mon, 31 Oct 1977 03:14:00 -0500")
        #expect(formatter.string(from: Date(timeIntervalSince1970: 247133640.0)) == "Mon, 31 Oct 1977 08:14:00 +0000")
    }

    @Test func date() throws {
        let formatter: RFC822DateFormatter = RFC822DateFormatter()
        #expect(try formatter.date(from: "Mon, 31 Oct 1977 03:14:00-0500") == Date(timeIntervalSince1970: 247133640.0))
        #expect(try formatter.date(from: "Mon, 31 Oct 1977 08:14:00 +0000 (GMT)") == Date(timeIntervalSince1970: 247133640.0))
        #expect(try formatter.date(from: "Mon, 31 Oct 1977 08:14:00 GMT") == Date(timeIntervalSince1970: 247133640.0))
        #expect(throws: MIMEError.self) {
            try formatter.date(from: "31 10 77; 03:14:00 GMT")
        }
    }
}

extension StringTests {
    @Test func rfc822Format() {
        #expect(String.rfc822Format == "EEE, dd MMM yyyy HH:mm:ss Z")
    }
}

extension RFC822DateFormatterTests {
    @Test func dateRFC822Format() throws {
        let date: Date = Date(timeIntervalSince1970: 247133640.0)
        #expect(date.rfc822Format() == "Mon, 31 Oct 1977 08:14:00 +0000")
        #expect(date.rfc822Format(TimeZone(secondsFromGMT: -5 * 3600)!) == "Mon, 31 Oct 1977 03:14:00 -0500")
        #expect(try Date(rfc822Format: date.rfc822Format()) == date)
        #expect(throws: MIMEError.self) {
            try Date(rfc822Format: "not a date")
        }
    }
}

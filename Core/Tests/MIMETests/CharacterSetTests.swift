// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import MIME
import Testing

struct CharacterSetTests {
    @Test func ascii() {
        #expect(CharacterSet.ascii.rawValue == "US-ASCII")
    }

    @Test func descriptionInit() throws {
        #expect(try CharacterSet("ISO-8859-1").rawValue == "ISO-8859-1")
        #expect(try CharacterSet().rawValue == "US-ASCII")
        #expect(try CharacterSet("utf-8").rawValue == "UTF-8")
        #expect(throws: MIMEError.self) {
            try CharacterSet("UTF-16🌐")
        }
    }
}

extension CharacterSetTests {
    @Test func iso8859() {
        #expect(CharacterSet.iso8859.rawValue == "ISO-8859-1")
    }

    @Test func utf8() {
        #expect(CharacterSet.utf8.rawValue == "UTF-8")
    }
}

extension CharacterSetTests {
    @Test func rawValueInit() {
        #expect(CharacterSet(rawValue: "utf-8")?.rawValue == "UTF-8")
        #expect(CharacterSet(rawValue: "") == nil)
    }
}

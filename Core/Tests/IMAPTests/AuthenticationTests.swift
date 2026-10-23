// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import IMAP
import Testing

struct AuthenticationTests {
    @Test func initialResponse() throws {

    }

    // MARK: CustomStringConvertible
    @Test func description() {
        #expect(Authentication.xoauth2("user@example.com", token: "").description == "XOAUTH2 \"user@example.com\"")
    }
}

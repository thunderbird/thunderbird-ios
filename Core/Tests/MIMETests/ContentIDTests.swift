// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import MIME
import Testing

struct ContentIDTests {
    @Test func hostInit() {
        let date: Date = Date(timeIntervalSince1970: 1762463150.0)
        let uuid: UUID = UUID(uuidString: "87CC5B3E-28FF-4A3E-9340-8E2DA59DF7E8")!
        #expect(ContentID("example.com", date: date, uuid: uuid).description == "<1762463150.87CC5B3E@example.com>")
        #expect(ContentID(date: date, uuid: uuid).description == "<1762463150.87CC5B3E>")
    }

    @Test func descriptionInit() {
        #expect(ContentID("<1762463150.A51D5B17@example.com>").description == "<1762463150.A51D5B17@example.com>")
        #expect(ContentID("FR33$Ty13").description == "FR33$Ty13")
        #expect(ContentID("").description.components(separatedBy: ".").count == 2)
        #expect(ContentID("").description.count > 20)
    }
}

extension ContentIDTests {
    @Test func id() {
        #expect(ContentID("<1762463150.A51D5B17@example.com>").id == "<1762463150.A51D5B17@example.com>")
    }
}

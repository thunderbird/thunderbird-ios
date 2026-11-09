// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import MIME
import Testing

struct BoundaryTests {
    @Test func bounds() {
        #expect(Boundary.bounds == 1...70)
    }

    @Test func descriptionInit() throws {
        let description: String = UUID().uuidString
        #expect(try Boundary(description).description == description)
        #expect(try Boundary("======== ").description == "========")
        #expect(throws: MIMEError.boundaryNotASCII) {
            try Boundary("========👎")
        }
        #expect(throws: MIMEError.boundaryNotASCII) {
            try Boundary(String(repeating: "👎", count: 8))
        }
        #expect(throws: MIMEError.boundaryLength(0)) {
            try Boundary("")
        }
        #expect(throws: MIMEError.boundaryLength(71)) {
            try Boundary(String(repeating: "=", count: 71))
        }
    }
}

extension BoundaryTests {
    @Test func rawValueInit() {
        #expect(Boundary(rawValue: "abc")?.rawValue == "abc")
        #expect(Boundary(rawValue: "") == nil)
    }
}

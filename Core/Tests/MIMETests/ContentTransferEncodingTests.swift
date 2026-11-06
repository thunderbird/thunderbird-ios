// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import MIME
import Testing

struct ContentTransferEncodingTests {

    // MARK: RawRepresentable
    @Test func rawValueInit() {
        #expect(ContentTransferEncoding(rawValue: "7BIT") == .ascii)
        #expect(ContentTransferEncoding(rawValue: " base64") == .base64)
        #expect(ContentTransferEncoding(rawValue: "binary") == .binary)
        #expect(ContentTransferEncoding(rawValue: "8bit") == .data)
        #expect(ContentTransferEncoding(rawValue: "QUOTED-PRINTABLE") == .quotedPrintable)
        #expect(ContentTransferEncoding(rawValue: "16bit") == nil)
    }
}

extension ContentTransferEncodingTests {
    @Test func defaultEncoding() {
        #expect(ContentTransferEncoding.default == .ascii)
    }
}

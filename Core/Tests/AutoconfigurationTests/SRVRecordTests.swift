// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Autoconfiguration
import Foundation
import Testing

struct SRVRecordTests {
    //Expect: Decode the target host, port, weight and priority from the raw bytes.
    //Case: When the record has priority 0 and weight 1.
    @Test func init_decodesRecord_whenPriorityIsZero() throws {
        // Arrange
        let input = Data(base64Encoded: "AAAAAQG7BG1haWwLdGh1bmRlcm1haWwDY29tAA==")!
        let expected = "SRVRecord(host=mail.thundermail.com, port=443, weight=1, priority=0)"

        // Act
        let actual = try SRVRecord(input).description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the target host, port, weight and priority from the raw bytes.
    //Case: When the record has priority 5 and weight 0.
    @Test func init_decodesRecord_whenPriorityIsNonZero() throws {
        // Arrange
        let input = Data(base64Encoded: "AAUAAAPhBGltYXAFZ21haWwDY29tAA==")!
        let expected = "SRVRecord(host=imap.gmail.com, port=993, weight=0, priority=5)"

        // Act
        let actual = try SRVRecord(input).description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Throw a `URLError`.
    //Case: When the data is only 7 zero bytes, too short to hold a target host.
    @Test func init_throws_whenDataIsTooShort() {
        // Arrange
        let input = Data(base64Encoded: "AAAAAAAAAA==")!

        // Act & Assert
        #expect(throws: URLError.self) {
            try SRVRecord(input)
        }
    }
}

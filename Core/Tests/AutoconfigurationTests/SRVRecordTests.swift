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

    //Expect: Decode the target host with every label intact.
    //Case: When a label after the first is 32 characters, so its length byte is a printable space.
    @Test func init_decodesHost_whenLaterLabelIs32Characters() throws {
        // Arrange
        let label = String(repeating: "x", count: 32)
        let input = Self.rdata(port: 443, labels: ["mail", label, "com"])
        let expected = "mail.\(label).com"

        // Act
        let actual = try SRVRecord(input).host

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the target host with every label intact.
    //Case: When a label after the first is 63 characters, the longest DNS allows, so its length byte is a printable `?`.
    @Test func init_decodesHost_whenLaterLabelIs63Characters() throws {
        // Arrange
        let label = String(repeating: "x", count: 63)
        let input = Self.rdata(port: 443, labels: ["mail", label, "com"])
        let expected = "mail.\(label).com"

        // Act
        let actual = try SRVRecord(input).host

        // Assert
        #expect(actual == expected)
    }
}

extension SRVRecordTests {
    /// Raw SRV `rdata`: priority 0, weight 1 and `port`, then the target host as length-prefixed labels (RFC 1035 §3.1).
    static func rdata(port: UInt16, labels: [String]) -> Data {
        var data = Data([0, 0, 0, 1, UInt8(port >> 8), UInt8(port & 0xFF)])
        for label in labels {
            data.append(UInt8(label.utf8.count))
            data.append(contentsOf: label.utf8)
        }
        data.append(0)
        return data
    }
}

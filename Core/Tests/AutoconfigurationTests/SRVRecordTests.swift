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
    //Example: The length byte 32 is also the character code for a space. The old decoder split the name on unprintable
    //  characters (codes 0-31) instead of reading lengths, so it kept this one: `mail xxx….com` instead of `mail.xxx….com`.
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
    //Example: Character code 63 is `?`, so the old decoder produced `mail?xxx….com`. Any label of 32-63 characters
    //  after the first was affected; the first label was always fine because its length byte was skipped.
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
    /// Build the raw bytes a DNS server returns for an SRV record, so tests can give `SRVRecord(_:)` exact input
    /// without a network lookup.
    ///
    /// An SRV record's data (`rdata`) is six bytes of numbers followed by the target host name. The name isn't stored
    /// as text with dots; each part of it ("label") is stored as a length byte followed by that many characters, and
    /// a zero byte ends the name (RFC 1035 §3.1). For example, `mail.thundermail.com` on port 443 is:
    ///
    /// ```
    /// 00 00 | 00 01 | 01 BB | 04 m a i l | 0B t h u n d e r m a i l | 03 c o m | 00
    /// prio 0  weight 1  port 443  4 chars     11 chars                  3 chars   end
    /// ```
    ///
    /// - Parameters:
    ///   - port: Port to encode. Priority is always 0 and weight 1.
    ///   - labels: Parts of the host name, without dots, e.g. `["mail", "example", "com"]`.
    /// - Returns: The encoded record data.
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

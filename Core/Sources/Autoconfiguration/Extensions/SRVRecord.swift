// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AsyncDNSResolver
import Foundation

/// Extends `SRVRecord` with decoding from raw DNS record data.
extension SRVRecord {
    /// Decode an `AsyncDNSResolver` record from the raw SRV `rdata` delivered to ``SRVResolver``.
    ///
    /// The layout is big-endian priority, weight and port (2 bytes each), then the target name in DNS wire format:
    /// labels of up to 63 bytes, each preceded by its length, ending with a zero-length root label
    /// ([RFC 1035 §3.1](https://www.rfc-editor.org/rfc/rfc1035#section-3.1)). For example, `04 m a i l 03 c o m 00` is
    /// `mail.com`: read a length, take that many bytes as one label, and repeat until a length of zero.
    ///
    /// Adapted from https://github.com/jamf/NoMAD-2/blob/main/NoMAD/SRVLookups/SRVRecord.swift
    ///
    /// - Parameter data: Raw SRV `rdata` bytes.
    /// - Throws: `URLError(.cannotDecodeRawData)` if the data is too short, a label is longer than 63 bytes, is cut off
    ///   or isn't UTF-8, the name doesn't end with the root label, or the target is `.`, which
    ///   [RFC 2782](https://www.rfc-editor.org/rfc/rfc2782) uses to mean no service is available.
    init(_ data: Data) throws {
        let bytes: [UInt8] = Array(data)  // Index from 0, whatever `data`'s start index
        guard bytes.count > 6 else {
            throw URLError(.cannotDecodeRawData)
        }
        var labels: [String] = []
        var index: Int = 6  // Target name starts after priority, weight and port
        // Read the length byte, then that many bytes as one label; a length of 0 ends the name. Reading lengths is
        // what fixes the old decoder, which split on unprintable bytes and kept lengths 32-63 because they're printable.
        while index < bytes.count, bytes[index] != 0 {
            let length: Int = Int(bytes[index])
            guard length <= 63, index + length < bytes.count,  // Longer lengths are compression pointers, not allowed here
                let label: String = String(bytes: bytes[(index + 1)...(index + length)], encoding: .utf8)
            else {
                throw URLError(.cannotDecodeRawData)
            }
            labels.append(label)
            index += length + 1
        }
        guard index < bytes.count, !labels.isEmpty else {  // Missing root label, or a `.` target
            throw URLError(.cannotDecodeRawData)
        }
        let priority: UInt16 = (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
        let weight: UInt16 = (UInt16(bytes[2]) << 8) | UInt16(bytes[3])
        let port: UInt16 = (UInt16(bytes[4]) << 8) | UInt16(bytes[5])
        self.init(host: labels.joined(separator: "."), port: port, weight: weight, priority: priority)
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AsyncDNSResolver
import Foundation

extension SRVRecord {
    // Decode `AsyncDNSResolver` model from `SRVResolver` bytes
    // Adapted from https://github.com/jamf/NoMAD-2/blob/main/NoMAD/SRVLookups/SRVRecord.swift
    init(_ data: Data) throws {
        // Expect a sequence of more than 8 bytes
        // Host name encoded as UTF-8 string of variable length, taking byte 8 through end of sequence
        guard data.count > 8, var host: String = String(bytes: data.suffix(from: 7), encoding: .utf8) else {
            throw URLError(.cannotDecodeRawData)
        }
        host = host.components(separatedBy: .controlCharacters).filter { !$0.isEmpty }.joined(separator: ".")
        let priority: UInt16 = (UInt16(data[0]) * 256) + UInt16(data[1])  // Decode priority number from bytes 1 + 2
        let weight: UInt16 = (UInt16(data[2]) * 256) + UInt16(data[3])  // Decode weight number from bytes 3 + 4
        let port: UInt16 = (UInt16(data[4]) * 256) + UInt16(data[5])  // Decode port number from bytes 5 + 6
        // Byte 7 is a discarded control character/delimiter
        self.init(host: host, port: port, weight: weight, priority: priority)
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AsyncDNSResolver
import Foundation

extension SRVRecord {
    /// Decode an `AsyncDNSResolver` record from the raw SRV `rdata` delivered to ``SRVResolver``.
    ///
    /// The layout is big-endian priority, weight and port (2 bytes each), then the target name in DNS wire format
    /// (length-prefixed labels). Length bytes below 32 decode as control characters, so splitting on them recovers
    /// the labels. A label after the first that is 32 characters or longer has a printable length byte, which is kept
    /// as part of the host name: `mail.<48 × x>.com` decodes as `mail0xxx….com`.
    ///
    /// Adapted from https://github.com/jamf/NoMAD-2/blob/main/NoMAD/SRVLookups/SRVRecord.swift
    ///
    /// - Parameter data: Raw SRV `rdata` bytes.
    /// - Throws: `URLError(.cannotDecodeRawData)` if the data is too short or the target isn't UTF-8.
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
        // Byte 7 is the first label's length prefix, discarded by `suffix(from: 7)`
        self.init(host: host, port: port, weight: weight, priority: priority)
    }
}

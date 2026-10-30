// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// Parse the Public Suffix List: https://publicsuffix.org
struct SuffixListParser: CustomStringConvertible {
    let suffixList: [String]
    let data: Data

    init(data: Data) throws {
        guard let description: String = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeRawData)
        }
        self.suffixList = description.suffixList
        guard !suffixList.isEmpty else {
            throw URLError(.cannotDecodeContentData)
        }
        self.data = data
        self.description = description
    }

    // MARK: CustomStringConvertible
    let description: String
}

private extension String {
    var suffixList: [String] { components(separatedBy: "\n").filter { $0.isSuffix } }
    private var isSuffix: Bool { !hasPrefix("//") && !isEmpty }
}

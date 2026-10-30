// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Parses the [Public Suffix List](https://publicsuffix.org) into its suffix entries.
///
/// Comment lines (`//`) and blank lines are skipped. Other lines, including wildcard and exception rules, are kept
/// verbatim.
struct SuffixListParser: CustomStringConvertible {
    /// Suffix entries, in file order.
    let suffixList: [String]
    /// Raw list data the parser was created from.
    let data: Data

    /// Parse Public Suffix List data.
    ///
    /// - Parameter data: UTF-8 contents of the list.
    /// - Throws: `URLError(.cannotDecodeRawData)` if the data isn't UTF-8, or `URLError(.cannotDecodeContentData)` if
    ///   it contains no suffixes.
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

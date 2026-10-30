// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Derives the registrable domain (public suffix plus one label) from a host name using a Public Suffix List.
///
/// For example, `mail.example.co.uk` with suffix `co.uk` yields the domain `example.co.uk`.
/// Wildcard (`*.`) and exception (`!`) rules in the list are not interpreted.
struct DomainParser {
    /// Registrable domain: the matched suffix plus one preceding label.
    let domain: String
    /// Host name the domain was derived from.
    let host: String
    /// Last public suffix in the list that `host` ends with.
    let suffix: String

    /// Derive the domain from the host of an email address.
    ///
    /// - Parameters:
    ///   - emailAddress: An email address or bare host name.
    ///   - suffixList: Public suffixes, as produced by ``SuffixListParser``.
    /// - Throws: `URLError(.cannotFindHost)` if no host can be parsed, or `URLError(.dnsLookupFailed)` if no suffix
    ///   matches.
    init(_ emailAddress: String, suffixList: [String]) throws {
        let host: String = try emailAddress.host
        try self.init(host: host, suffixList: suffixList)
    }

    /// Derive the domain from a host name.
    ///
    /// The last matching entry wins, so the list is expected to be ordered with more specific suffixes later.
    ///
    /// - Parameters:
    ///   - host: A host name.
    ///   - suffixList: Public suffixes, as produced by ``SuffixListParser``.
    /// - Throws: `URLError(.dnsLookupFailed)` if no suffix matches `host`.
    init(host: String, suffixList: [String]) throws {
        guard let suffix: String = suffixList.filter({ host.hasSuffix(".\($0)") }).last else {
            throw URLError(.dnsLookupFailed)
        }
        let segments: (host: [String], suffix: [String]) = (host.segments, suffix.segments)
        self.domain = segments.host.dropFirst(segments.host.count - (segments.suffix.count + 1)).joined(separator: ".")
        self.host = host
        self.suffix = suffix
    }
}

private extension String {
    var segments: [Self] { components(separatedBy: ".") }
}

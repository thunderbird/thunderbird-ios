// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension URL {
    /// Generate the appropriate autoconfig URL for a given source and email address.
    ///
    /// - Parameters:
    ///   - emailAddress: An email address or bare host name.
    ///   - source: Where to look for the configuration. Defaults to ``Source/ispDB``.
    /// - Returns: The URL of the autoconfig document.
    /// - Throws: `URLError(.cannotFindHost)` if no host can be parsed, or `URLError(.unsupportedURL)` if the URL can't
    ///   be built.
    public static func autoconfig(_ emailAddress: String, source: Source = .ispDB) throws -> Self {
        switch source {
        case .provider: try provider(emailAddress)
        case .wellKnown: try wellKnown(emailAddress)
        case .ispDB: try ispDB(emailAddress)
        }
    }

    /// `https://autoconfig.<host>/mail/config-v1.1.xml`, with an `emailaddress` query item when a full address is
    /// given.
    ///
    /// - Parameter emailAddress: An email address or bare host name.
    /// - Returns: The provider's autoconfig URL.
    /// - Throws: `URLError(.cannotFindHost)` or `URLError(.unsupportedURL)`.
    static func provider(_ emailAddress: String) throws -> Self {
        let host: String = try emailAddress.host
        guard let url: URL = URL(string: "https://autoconfig.\(host)/mail/config-v1.1.xml") else {
            throw URLError(.unsupportedURL)
        }
        return emailAddress != host
            ? url.appending(queryItems: [
                URLQueryItem(name: "emailaddress", value: emailAddress)
            ]) : url
    }

    /// `https://<host>/.well-known/autoconfig/mail/config-v1.1.xml`.
    ///
    /// - Parameter emailAddress: An email address or bare host name.
    /// - Returns: The provider's well-known autoconfig URL.
    /// - Throws: `URLError(.cannotFindHost)` or `URLError(.unsupportedURL)`.
    static func wellKnown(_ emailAddress: String) throws -> Self {
        let host: String = try emailAddress.host
        guard let url: URL = URL(string: "https://\(host)/.well-known/autoconfig/mail/config-v1.1.xml") else {
            throw URLError(.unsupportedURL)
        }
        return url
    }

    /// Thunderbird's ISP database entry for the host: `https://autoconfig.thunderbird.net/v1.1/<host>`.
    ///
    /// - Parameter emailAddress: An email address or bare host name.
    /// - Returns: The ISPDB URL for the host.
    /// - Throws: `URLError(.cannotFindHost)` or `URLError(.unsupportedURL)`.
    static func ispDB(_ emailAddress: String) throws -> Self {
        let host: String = try emailAddress.host
        guard let url: URL = URL(string: "https://autoconfig.thunderbird.net/v1.1/\(host)") else {
            throw URLError(.unsupportedURL)
        }
        return url
    }
}

extension URL {
    /// Location of the Public Suffix List.
    static let suffixList: Self = Self(string: "https://publicsuffix.org/list/public_suffix_list.dat")!
}

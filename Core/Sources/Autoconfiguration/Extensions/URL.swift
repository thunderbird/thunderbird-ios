// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Extends `URL` with the locations of autoconfig documents.
extension URL {
    /// Generate the appropriate autoconfig URL for a given source and email address.
    ///
    /// - Parameters:
    ///   - emailAddress: An email address or bare host name.
    ///   - source: Where to look for the configuration. Defaults to ``Source/ispDB``.
    ///   - domain: Domain to look up instead of `emailAddress`'s host, such as one derived from an MX host. Defaults to
    ///     `nil`, which uses the address's host.
    /// - Returns: The URL of the autoconfig document.
    /// - Throws: `URLError(.cannotFindHost)` if no host can be parsed, or `URLError(.unsupportedURL)` if the URL can't
    ///   be built.
    public static func autoconfig(_ emailAddress: String, source: Source = .ispDB, domain: String? = nil) throws -> Self {
        switch source {
        case .provider: try provider(emailAddress, domain: domain)
        case .wellKnown: try wellKnown(emailAddress, domain: domain)
        case .ispDB: try ispDB(emailAddress, domain: domain)
        }
    }

    /// `https://autoconfig.<host>/mail/config-v1.1.xml`, with an `emailaddress` query item when a full address is
    /// given.
    ///
    /// The query value is percent-encoded, including `+`, so a plus-addressed email reaches the provider intact.
    ///
    /// - Parameters:
    ///   - emailAddress: An email address or bare host name.
    ///   - domain: Domain to use in place of `emailAddress`'s host. The `emailaddress` query item still uses
    ///     `emailAddress`. Defaults to `nil`.
    /// - Returns: The provider's autoconfig URL.
    /// - Throws: `URLError(.cannotFindHost)` or `URLError(.unsupportedURL)`.
    static func provider(_ emailAddress: String, domain: String? = nil) throws -> Self {
        let host: String = try domain ?? emailAddress.host
        guard var components: URLComponents = URLComponents(string: "https://autoconfig.\(host)/mail/config-v1.1.xml") else {
            throw URLError(.unsupportedURL)
        }
        if emailAddress != (try emailAddress.host) {  // Full email address, not a bare host
            components.setQueryItemsEncodingPlus([
                URLQueryItem(name: "emailaddress", value: emailAddress)
            ])
        }
        guard let url: URL = components.url else {
            throw URLError(.unsupportedURL)
        }
        return url
    }

    /// `https://<host>/.well-known/autoconfig/mail/config-v1.1.xml`.
    ///
    /// - Parameters:
    ///   - emailAddress: An email address or bare host name.
    ///   - domain: Domain to use in place of `emailAddress`'s host. Defaults to `nil`.
    /// - Returns: The provider's well-known autoconfig URL.
    /// - Throws: `URLError(.cannotFindHost)` or `URLError(.unsupportedURL)`.
    static func wellKnown(_ emailAddress: String, domain: String? = nil) throws -> Self {
        let host: String = try domain ?? emailAddress.host
        guard let url: URL = URL(string: "https://\(host)/.well-known/autoconfig/mail/config-v1.1.xml") else {
            throw URLError(.unsupportedURL)
        }
        return url
    }

    /// Thunderbird's ISP database entry for the host: `https://autoconfig.thunderbird.net/v1.1/<host>`.
    ///
    /// - Parameters:
    ///   - emailAddress: An email address or bare host name.
    ///   - domain: Domain to use in place of `emailAddress`'s host. Defaults to `nil`.
    /// - Returns: The ISPDB URL for the host.
    /// - Throws: `URLError(.cannotFindHost)` or `URLError(.unsupportedURL)`.
    static func ispDB(_ emailAddress: String, domain: String? = nil) throws -> Self {
        let host: String = try domain ?? emailAddress.host
        guard let url: URL = URL(string: "https://autoconfig.thunderbird.net/v1.1/\(host)") else {
            throw URLError(.unsupportedURL)
        }
        return url
    }
}

/// Extends `URL` with the locations of reference data the package downloads.
extension URL {
    /// Location of the Public Suffix List.
    static let suffixList: Self = Self(string: "https://publicsuffix.org/list/public_suffix_list.dat")!
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension URLSession {
    /// Query multiple autoconfig sources for a given email address.
    ///
    /// Sources are tried in order and the first that succeeds wins; individual source failures are ignored. If all fail
    /// and `queryMX` is `true`, the domain of the first MX host is derived and the sources are retried once for it.
    ///
    /// - Important: The MX retry queries with the derived domain in place of `emailAddress`, so the provider URL omits
    ///   the `emailaddress` query item, and placeholders such as `%EMAILADDRESS%` in the returned configuration are
    ///   substituted with that domain rather than the user's address.
    /// - Parameters:
    ///   - emailAddress: Email address to configure.
    ///   - sources: Sources to query, in order of trust. Defaults to all sources.
    ///   - queryMX: Whether to fall back to the MX host's domain. Defaults to `true`.
    /// - Returns: The configuration and the source that provided it.
    /// - Throws: `URLError(.fileDoesNotExist)` if no source succeeds, including after the MX retry;
    ///   `URLError(.unsupportedURL)` if there are no MX records; or a DNS, network or ``domain(host:)`` error.
    public func autoconfig(_ emailAddress: String, sources: [Source] = Source.allCases, queryMX: Bool = true) async throws -> (config: ClientConfig, source: Source) {
        for source in sources {
            guard let config: ClientConfig = try? await autoconfig(emailAddress, source: source).config else { continue }
            return (config, source)
        }
        guard queryMX else {
            throw URLError(.fileDoesNotExist)
        }
        let records: [MXRecord] = try await DNSResolver.queryMX(emailAddress)
        guard let host: String = records.first?.host else {
            throw URLError(.unsupportedURL)
        }
        let domain: String = try await domain(host: host)
        return try await autoconfig(domain, sources: sources, queryMX: false)
    }

    /// Query a single autoconfig source using a given email address.
    ///
    /// - Parameters:
    ///   - emailAddress: Email address to configure.
    ///   - source: The source to query.
    /// - Returns: The decoded configuration and the data behind it: the translated JSON, then the original XML.
    /// - Throws: `URLError(.fileDoesNotExist)` on HTTP 404, `URLError(.unsupportedURL)` on any other non-200 response,
    ///   or a parsing, decoding or network error.
    public func autoconfig(_ emailAddress: String, source: Source) async throws -> (config: ClientConfig, data: (Data, Data)) {
        let url: URL = try .autoconfig(emailAddress, source: source)
        let data: (Data, URLResponse) = try await data(from: url)
        switch (data.1 as? HTTPURLResponse)?.statusCode {
        case 200:
            let json: Data = try XMLToJSONParser(emailAddress, data: data.0).data
            let container: Container = try JSONDecoder().decode(Container.self, from: json)
            return (container.clientConfig, (json, data.0))
        case 404:
            throw URLError(.fileDoesNotExist)
        default:
            throw URLError(.unsupportedURL)
        }
    }

    private struct Container: Decodable {
        let clientConfig: ClientConfig
    }
}

extension URLSession {
    /// Derive the registrable domain of a host name using the [Public Suffix List](https://publicsuffix.org).
    ///
    /// - Parameter host: A host name, such as an MX record host.
    /// - Returns: The registrable domain, e.g. `example.co.uk` for `mail.example.co.uk`.
    /// - Throws: `URLError(.dnsLookupFailed)` if no public suffix matches, or a network or parsing error.
    public func domain(host: String) async throws -> String {
        let suffixList: [String] = try await suffixList()
        let parser: DomainParser = try DomainParser(host: host, suffixList: suffixList)
        return parser.domain
    }

    /// Download and parse the Public Suffix List.
    ///
    /// - Returns: The suffix entries.
    /// - Throws: A network error, or a ``SuffixListParser`` error.
    func suffixList() async throws -> [String] {
        let data: (Data, URLResponse) = try await data(from: .suffixList)
        let suffixList: [String] = try SuffixListParser(data: data.0).suffixList
        return suffixList
    }
}

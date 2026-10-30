// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@_exported import AsyncDNSResolver
import Foundation

/// DNS resolver used for autoconfiguration lookups, re-exported from `AsyncDNSResolver`.
public typealias DNSResolver = AsyncDNSResolver

extension DNSResolver {
    /// Query SRV records for several email services, concatenating the results in `services` order.
    ///
    /// - Parameters:
    ///   - emailAddress: An email address or bare host name; only the host is queried.
    ///   - services: Services to query. Defaults to every ``Service``.
    /// - Returns: The SRV records found for all services; services with no records contribute none.
    /// - Throws: `URLError(.cannotFindHost)` if the host can't be parsed, or if any single query fails or times out. A
    ///   failure for one service aborts the whole call; no partial results are returned.
    public static func querySRV(_ emailAddress: String, services: [Service] = Service.allCases) async throws -> [SRVRecord] {
        var records: [SRVRecord] = []
        for service in services {
            records += try await querySRV(emailAddress, service: service)
        }
        return records
    }

    /// Query SRV records (`_<service>._tcp.<host>`) for a single email service.
    ///
    /// - Parameters:
    ///   - emailAddress: An email address or bare host name; only the host is queried.
    ///   - service: The service to query.
    /// - Returns: The SRV records for the service, in the order DNS returned them; empty if there are none.
    /// - Throws: `URLError(.cannotFindHost)` if the host can't be parsed or the lookup fails or times out.
    public static func querySRV(_ emailAddress: String, service: Service) async throws -> [SRVRecord] {
        let query: String = try emailAddress.query(service)
        let records: [SRVRecord] = try await SRVResolver().query(query)  // `AsyncDNSResolver` SRV querying doesn't work; fall back to `dnssd`-based resolver
        return records
    }

    /// Query MX records for the host of an email address.
    ///
    /// - Parameter emailAddress: An email address or bare host name; only the host is queried.
    /// - Returns: The MX records for the host.
    /// - Throws: `URLError(.cannotFindHost)` if the host can't be parsed, or an error from `AsyncDNSResolver`.
    public static func queryMX(_ emailAddress: String) async throws -> [MXRecord] {
        let host: String = try emailAddress.host
        let resolver: Self = try Self()
        let records: [MXRecord] = try await resolver.queryMX(name: host)
        return records
    }
}

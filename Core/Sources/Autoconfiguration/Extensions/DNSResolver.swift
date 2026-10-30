// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@_exported import AsyncDNSResolver
import Foundation

public typealias DNSResolver = AsyncDNSResolver

extension DNSResolver {
    public static func querySRV(_ emailAddress: String, services: [Service] = Service.allCases) async throws -> [SRVRecord] {
        var records: [SRVRecord] = []
        for service in services {
            records += try await querySRV(emailAddress, service: service)
        }
        return records
    }

    public static func querySRV(_ emailAddress: String, service: Service) async throws -> [SRVRecord] {
        let query: String = try emailAddress.query(service)
        let records: [SRVRecord] = try await SRVResolver().query(query)  // `AsyncDNSResolver` SRV querying doesn't work; fall back to `dnssd`-based resolver
        return records
    }

    public static func queryMX(_ emailAddress: String) async throws -> [MXRecord] {
        let host: String = try emailAddress.host
        let resolver: Self = try Self()
        let records: [MXRecord] = try await resolver.queryMX(name: host)
        return records
    }
}

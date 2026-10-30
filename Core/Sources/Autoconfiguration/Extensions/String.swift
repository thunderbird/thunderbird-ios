// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension String {
    /// The validated host portion of an email address or bare host name.
    ///
    /// Everything after the last `@` is used.
    ///
    /// - Throws: `URLError(.cannotFindHost)` if no valid host can be extracted.
    public var host: Self {
        get throws {
            // Ensure valid host/domain with `URL` initializer, then discard the `URL`.
            guard let url: URL = URL(string: "http://\(components(separatedBy: "@").last!)"),
                let host: String = url.host()
            else {
                throw URLError(.cannotFindHost)
            }
            return host
        }
    }

    /// The local part of an email address: everything before the last `@`.
    ///
    /// - Throws: `URLError(.cannotFindHost)` if the string contains no `@`.
    public var local: Self {
        get throws {
            guard contains("@") else {
                throw URLError(.cannotFindHost)
            }
            return components(separatedBy: "@").dropLast().joined(separator: "@")
        }
    }

    /// The DNS SRV query name for a service at this address's host, e.g. `_imaps._tcp.example.com`.
    ///
    /// - Parameter service: The service to build the query name for.
    /// - Returns: The query name, `_<service>._tcp.<host>`.
    /// - Throws: `URLError(.cannotFindHost)` if no valid host can be extracted.
    public func query(_ service: Service) throws -> Self {
        "_\(service.rawValue)._tcp.\(try host)"
    }
}

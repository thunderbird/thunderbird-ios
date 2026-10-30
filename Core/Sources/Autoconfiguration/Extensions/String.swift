// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension String {
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

    public var local: Self {
        get throws {
            guard contains("@") else {
                throw URLError(.cannotFindHost)
            }
            return components(separatedBy: "@").dropLast().joined(separator: "@")
        }
    }

    public func query(_ service: Service) throws -> Self {
        "_\(service.rawValue)._tcp.\(try host)"
    }
}

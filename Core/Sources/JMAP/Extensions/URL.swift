// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension URL {

    /// Generate ``Session`` URL from host and port number.
    ///
    /// All additional URLs and URL templates needed to implement a complete JMAP service are provided in the ``Session``.
    public static func jmapSession(host: String, port: Int? = nil) throws -> Self {
        try jmap(host: host, port: port, path: "jmap/session")
    }

    static func jmap(host: String, port: Int? = nil, path: String? = nil) throws -> Self {
        var components: URLComponents = URLComponents()
        components.scheme = "https"
        guard !host.isEmpty else {
            throw URLError(.cannotFindHost)
        }
        components.host = host
        components.port = port
        if let path, !path.isEmpty {
            components.path = path.hasPrefix("/") ? path : "/\(path)"
        }
        guard let url: Self = components.url else {
            throw URLError(.unsupportedURL)
        }
        return url
    }
}

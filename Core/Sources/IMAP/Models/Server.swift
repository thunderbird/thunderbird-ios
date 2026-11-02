// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// ``IMAPClient`` connects to `Server`.
public struct Server: CustomStringConvertible, Equatable, Sendable {
    public let connectionSecurity: ConnectionSecurity
    public let authentication: Authentication?
    public let hostname: String
    public let port: Int

    /// `Server` can be configured with or without authentication credentials.
    public init(
        _ connectionSecurity: ConnectionSecurity = .tls,
        authentication: Authentication? = nil,
        hostname: String,
        port: Int = 993
    ) {
        self.connectionSecurity = connectionSecurity
        self.authentication = authentication
        self.hostname = hostname
        self.port = port
    }

    // MARK: CustomStringConvertible
    public var description: String { "\(hostname):\(port)" }
}

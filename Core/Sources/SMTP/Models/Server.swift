// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// ``SMTPClient`` connects to `Server`.
public struct Server: CustomStringConvertible, Equatable, Sendable {
    public let connectionSecurity: ConnectionSecurity
    public let hostname: String
    public let username: String
    public let password: String
    public let port: Int

    public init(
        _ connectionSecurity: ConnectionSecurity = .startTLS,
        hostname: String,
        username: String,
        password: String,
        port: Int = 587
    ) {
        self.connectionSecurity = connectionSecurity
        self.hostname = hostname
        self.username = username
        self.password = password
        self.port = port
    }

    // MARK: CustomStringConvertible
    public var description: String { "\(hostname):\(port)" }
}

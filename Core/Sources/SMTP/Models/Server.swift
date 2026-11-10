// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// An SMTP server to send through, with the credentials to sign in. ``SMTPClient`` connects to `Server`.
///
/// `description` is `hostname:port`, so logging a server doesn't reveal its credentials.
public struct Server: CustomStringConvertible, Equatable, Sendable {
    /// How the connection is secured.
    public let connectionSecurity: ConnectionSecurity
    public let hostname: String
    /// The user name for `AUTH LOGIN`, usually the email address.
    public let username: String
    /// The password for `AUTH LOGIN`. It's sent base64-encoded, which anyone can read unless the connection is
    /// encrypted.
    public let password: String
    public let port: Int

    /// Make a server from its address and credentials.
    ///
    /// - Parameters:
    ///   - connectionSecurity: How to secure the connection. Defaults to STARTTLS.
    ///   - hostname: The server's host name.
    ///   - username: The user name to sign in with.
    ///   - password: The password to sign in with.
    ///   - port: The port to connect to. Defaults to 587, the mail submission port.
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

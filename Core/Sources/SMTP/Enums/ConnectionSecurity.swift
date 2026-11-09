// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// How an SMTP connection is secured.
///
/// The raw value is also the description, and is what is stored when the type is encoded.
public enum ConnectionSecurity: String, Codable, CaseIterable, CustomStringConvertible, Identifiable, Sendable {
    /// Connect in plain text, then upgrade with the `STARTTLS` command. Usually on port 587.
    case startTLS = "STARTTLS"
    /// Encrypt from the start (implicit TLS). Usually on port 465.
    ///
    /// - Important: Sending with this setting currently always fails after the server's greeting; see
    ///   `SendHandler`.
    case tls = "SSL/TLS"
    /// No encryption. The user name, password and email are sent in plain text.
    case none

    /// Another name for ``ConnectionSecurity/tls``.
    public static var ssl: Self { .tls }

    // MARK: CustomStringConvertible
    public var description: String { rawValue }

    // MARK: Identifiable
    public var id: String { rawValue }
}

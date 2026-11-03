// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Provider details from the `emailProvider` element of an Autoconfig document.
public struct EmailProvider: Decodable {
    /// An incoming or outgoing mail server.
    public struct Server: Decodable {
        /// Authentication method, using the raw values defined by the Autoconfig format.
        ///
        /// Only a subset of the format's methods is supported. Decoding an unlisted method (e.g. `GSSAPI`, `NTLM`)
        /// throws, which fails decoding of the whole ``ClientConfig``.
        public enum Authentication: String, CaseIterable, CustomStringConvertible, Decodable {
            case clientIPAddress = "client-IP-address"
            case oAuth2 = "OAuth2"
            case passwordCleartext = "password-cleartext"
            case passwordEncrypted = "password-encrypted"
            case smtpAfterPop = "smtp-after-pop"

            // MARK: CustomStringConvertible
            public var description: String {
                switch self {
                case .clientIPAddress, .oAuth2: rawValue
                case .passwordCleartext: "clear-text password"
                case .passwordEncrypted: "encrypted password"
                case .smtpAfterPop: "SMTP after POP"
                }
            }
        }

        /// Mail protocol. `imap` and `pop3` are incoming; `smtp` is outgoing.
        public enum ServerType: String, CaseIterable, CustomStringConvertible, Decodable {
            case imap, pop3, smtp

            // MARK: CustomStringConvertible
            public var description: String { rawValue.uppercased() }
        }

        /// Connection security: `STARTTLS` upgrades a plain connection, `SSL` is implicit TLS.
        ///
        /// Unencrypted (`plain`) servers aren't supported. Decoding one throws, which fails decoding of the whole
        /// ``ClientConfig``.
        public enum SocketType: String, CaseIterable, CustomStringConvertible, Decodable {
            case startTLS = "STARTTLS", ssl = "SSL"

            // MARK: CustomStringConvertible
            public var description: String { rawValue }
        }

        /// Acceptable authentication methods, in the provider's order of preference.
        public let authentication: [Authentication]
        /// Server host name.
        public let hostname: String
        /// Server port.
        public let port: Int
        /// Protocol the server speaks.
        public let serverType: ServerType
        /// Connection security to use.
        public let socketType: SocketType
        /// Username, with placeholders such as `%EMAILADDRESS%` already substituted by ``XMLToJSONParser``.
        public let username: String
    }

    /// Full provider name, e.g. "Example Mail".
    public let displayName: String
    /// Abbreviated provider name.
    public let displayShortName: String
    /// Links to provider setup instructions.
    public let documentation: [URL]
    /// Primary domain the configuration applies to. Only the first `domain` element is kept.
    public let domain: String
    /// Incoming and outgoing servers, in document order.
    public let servers: [Server]
}

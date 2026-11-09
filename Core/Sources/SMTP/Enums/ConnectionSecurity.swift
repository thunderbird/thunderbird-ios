// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

public enum ConnectionSecurity: String, Codable, CaseIterable, CustomStringConvertible, Identifiable, Sendable {
    case startTLS = "STARTTLS"
    case tls = "SSL/TLS"
    case none

    public static var ssl: Self { .tls }

    // MARK: CustomStringConvertible
    public var description: String { rawValue }

    // MARK: Identifiable
    public var id: String { rawValue }
}

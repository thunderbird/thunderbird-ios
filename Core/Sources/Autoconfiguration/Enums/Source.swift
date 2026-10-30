// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Autoconfig locations to query, in order of trust: email provider subdomain or well-known, then ISPDB
public enum Source: String, CaseIterable, Codable, CustomStringConvertible, Sendable {
    case provider, wellKnown, ispDB  // Order of trust

    // MARK: CustomStringConvertible
    public var description: String {
        switch self {
        case .provider: "provider"
        case .wellKnown: "provider (alternate)"
        case .ispDB: "ISPDB"
        }
    }
}

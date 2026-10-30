// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Autoconfig locations to query. Cases are declared in order of trust, so `allCases` is the preferred query order.
///
/// See `URL.autoconfig(_:source:)` for the URL each source resolves to.
public enum Source: String, CaseIterable, Codable, CustomStringConvertible, Sendable {
    /// The provider's `autoconfig` subdomain.
    case provider
    /// The provider's `.well-known` path.
    case wellKnown
    /// Thunderbird's ISP database.
    case ispDB

    // MARK: CustomStringConvertible
    public var description: String {
        switch self {
        case .provider: "provider"
        case .wellKnown: "provider (alternate)"
        case .ispDB: "ISPDB"
        }
    }
}

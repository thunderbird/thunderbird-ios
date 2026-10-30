// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Standard email services/protocols to query DNS SRV records for
public enum Service: String, CaseIterable, CustomStringConvertible {
    case autodiscover, imap, imaps, jmap, smtp, submission

    // MARK: CustomStringConvertible
    public var description: String {
        switch self {
        case .autodiscover: rawValue.capitalized
        case .imap, .jmap, .smtp: rawValue.uppercased()
        case .imaps: Self.imap.description
        default: rawValue
        }
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Autoconfiguration

public enum AuthenticationType: String, Codable, CaseIterable, CustomStringConvertible, Identifiable, Sendable {
    case password
    case oauth2 = "OAuth2"
    case none

    // MARK: CustomStringConvertible
    public var description: String { rawValue }

    // MARK: Identifiable
    public var id: String { rawValue }
}

extension AuthenticationType {
    init(_ authentication: [EmailProvider.Server.Authentication]) {
        if authentication.contains(.oauth2) {
            self = .oauth2  // Prefer OAuth2
        } else if authentication.contains(.passwordCleartext) {
            self = .password
        } else {
            self = .none
        }
    }
}

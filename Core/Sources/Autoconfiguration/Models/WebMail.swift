// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Web mail details from the `webMail` element of an Autoconfig document.
public struct WebMail: Decodable {
    /// Web mail login page, with placeholders such as `%EMAILADDRESS%` already substituted.
    public let loginPage: URL
}

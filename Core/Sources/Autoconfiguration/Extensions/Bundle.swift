// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension Bundle {
    /// Read custom URL schemes declared in Info.plist
    public var schemes: [String] {
        guard let bundleURLType: [String: Any] = (object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]])?.first else {
            return []
        }
        return bundleURLType["CFBundleURLSchemes"] as? [String] ?? []
    }
}

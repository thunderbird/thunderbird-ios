// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension Locale {

    /// Generate a weighted `Accept-Language` HTTP request header matching the device's configured locales.
    ///
    /// JMAP services _should_ [localize user-facing strings](https://jmap.io/spec/rfc8620/#section-3.8) according to  header value.
    public static func acceptedLanguages() -> String {
        var languages: [String] = []
        for (index, language) in preferredLanguages.prefix(5).enumerated() {
            languages.append("\(language)\(index > 0 ? ";q=0.\(10 - index)" : "")")
        }
        languages.append("*;q=0.5")
        return languages.joined(separator: ", ")
    }
}

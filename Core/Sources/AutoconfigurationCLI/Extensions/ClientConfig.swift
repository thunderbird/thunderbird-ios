// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Autoconfiguration
#if canImport(Cocoa)
import Cocoa
#endif
import Foundation

/// Opening a configuration's web mail login page and documentation links.
extension ClientConfig {
    /// Open each of the provider's documentation links in the default browser.
    ///
    /// Does nothing if there are no links, or on platforms without Cocoa.
    ///
    /// - Throws: `URLError(.resourceUnavailable)` if the configuration has no email provider.
    func openDocumentation() throws {
        guard let urls: [URL] = emailProvider?.documentation else {
            throw URLError(.resourceUnavailable)
        }
        for url in urls {
            open(url)
        }
    }

    /// Open the web mail login page in the default browser. Does nothing on platforms without Cocoa.
    ///
    /// - Throws: `URLError(.resourceUnavailable)` if the configuration has no web mail login page.
    func openWebMailLoginPage() throws {
        guard let url: URL = webMail?.loginPage else {
            throw URLError(.resourceUnavailable)
        }
        open(url)
    }
}

/// Open a URL with `NSWorkspace`. Does nothing on platforms without Cocoa.
// swift-format-ignore
private func open(_ url: URL) {
#if canImport(Cocoa)
    NSWorkspace.shared.open(url)
#endif
}

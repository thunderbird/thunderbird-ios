// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if canImport(Cocoa)
import Cocoa
#endif
import Foundation

/// Extends `Bundle` with access to the folder that contains the running executable.
// swift-format-ignore
extension Bundle {
    /// Folder containing the running executable; where `autoconfig --save` writes its files.
    var executableDirectory: URL { executableURL!.deletingLastPathComponent() }

    /// Show ``executableDirectory`` in Finder. Does nothing on platforms without Cocoa.
    func showExecutableInFinder() {
#if canImport(Cocoa)
        NSWorkspace.shared.open(executableDirectory)
#endif
    }
}

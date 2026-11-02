// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Autoconfiguration
import Foundation

/// Extends `FileManager` with methods for saving autoconfig lookups to disk.
extension FileManager {
    /// Save an autoconfig lookup's JSON and XML to `<url>/<emailAddress>/config.json` and `config.xml`.
    ///
    /// Any existing folder for the address is deleted first, so saving again replaces the previous files.
    ///
    /// - Parameters:
    ///   - emailAddress: Email address the configuration is for; used as the folder name.
    ///   - data: The translated JSON and original XML, as returned by `URLSession.autoconfig(_:source:)`.
    ///   - url: Existing folder to save into. Defaults to the executable's folder.
    /// - Throws: `URLError(.fileDoesNotExist)` if `url` isn't an existing folder, or a file system error if the folder or
    ///   files can't be written.
    func save(_ emailAddress: String, data: (Data, Data), to url: URL = Bundle.main.executableDirectory) throws {
        guard fileExists(at: url, isDirectory: true) else {
            throw URLError(.fileDoesNotExist)
        }
        let url: URL = url.appending(path: emailAddress, directoryHint: .isDirectory)
        try? removeItem(at: url)
        try createDirectory(at: url, withIntermediateDirectories: false)
        try data.0.write(to: url.appending(component: "config.json"))
        try data.1.write(to: url.appending(component: "config.xml"))
    }

    /// Whether a file or folder exists at a URL, optionally requiring it to be a folder or a file.
    ///
    /// - Parameters:
    ///   - url: Location to check.
    ///   - isDirectory: `true` to require a folder, `false` to require a file, or `nil` to accept either.
    /// - Returns: `true` if something exists at `url` and, when `isDirectory` is set, it's the requested kind.
    func fileExists(at url: URL, isDirectory: Bool? = nil) -> Bool {
        var _isDirectory: ObjCBool = false
        guard fileExists(atPath: url.path(), isDirectory: &_isDirectory) else {
            return false
        }
        return isDirectory != nil ? isDirectory! == _isDirectory.boolValue : true
    }
}

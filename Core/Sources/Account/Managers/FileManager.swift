// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Utilities for persisting accounts to disk as JSON.
///
/// These helpers provide a lightweight, file-based store suitable for development and testing.
extension FileManager {
    /// Reads accounts from a JSON file at the given URL.
    ///
    /// - Parameter url: The file URL pointing to the JSON file.
    /// - Returns: An array of decoded `Account` values.
    /// - Throws: `URLError.fileDoesNotExist` if the file cannot be found, or any decoding error encountered.
    func readAccounts(from url: URL) throws -> [Account] {
        lock.lock()
        defer {
            lock.unlock()
        }
        guard try fileExists(at: url) else {
            throw URLError(.fileDoesNotExist)
        }
        let data: Data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Account].self, from: data)
    }

    /// Writes the provided accounts to disk as pretty-printed JSON, replacing any existing file.
    ///
    /// - Parameters:
    ///   - accounts: The accounts to persist.
    ///   - url: The file URL where the JSON should be written.
    /// - Throws: An error if encoding or writing fails.
    func write(_ accounts: [Account], to url: URL) throws {
        lock.lock()
        defer {
            lock.unlock()
        }
        let data: Data = try JSONEncoder(.prettyPrinted).encode(accounts)
        try? removeItem(at: url)
        guard !accounts.isEmpty else { return }
        try data.write(to: url)
    }

    /// Checks whether a file exists at a file URL.
    ///
    /// - Parameter url: The URL to check. Must be a file URL.
    /// - Returns: `true` if a file exists at the path; otherwise, `false`.
    /// - Throws: `URLError.unsupportedURL` if the URL is not a file URL.
    func fileExists(at url: URL) throws -> Bool {
        guard url.isFileURL else {
            throw URLError(.unsupportedURL)
        }
        return fileExists(atPath: url.path())
    }
}

/// Convenience initializers for `JSONEncoder`.
extension JSONEncoder {
    /// Creates a JSON encoder preconfigured with the specified output formatting.
    ///
    /// - Parameter outputFormatting: The output formatting options to apply.
    convenience init(_ outputFormatting: OutputFormatting) {
        self.init()
        self.outputFormatting = outputFormatting
    }
}

/// Convenience URLs for account persistence locations.
extension URL {
    /// The default location for the accounts JSON file.
    static var accounts: Self { documents("Accounts.json") }

    /// Constructs a URL in the documents (or temporary during tests) directory.
    ///
    /// - Parameter path: An optional path component to append.
    /// - Returns: A URL in the appropriate container.
    static func documents(_ path: String = "") -> Self {
        (isTestEnvironment ? Self.temporaryDirectory : .documentsDirectory).appending(path: path)
    }
}

/// Test environment detection.
extension ProcessInfo {
    /// Indicates whether the current process is running under XCTest.
    var isTestEnvironment: Bool { environment["XCTestSessionIdentifier"] != nil }
}

/// A convenience global that mirrors `ProcessInfo.processInfo.isTestEnvironment`.
var isTestEnvironment: Bool { ProcessInfo.processInfo.isTestEnvironment }

/// A shared lock used to serialize file access.
private let lock: NSLock = NSLock()

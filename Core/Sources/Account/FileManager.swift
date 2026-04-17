import Foundation

// Read and write accounts to JSON file on disk; stopgap for account persistence
extension FileManager {
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

    func fileExists(at url: URL) throws -> Bool {
        guard url.isFileURL else {
            throw URLError(.unsupportedURL)
        }
        return fileExists(atPath: url.path())
    }
}

extension JSONEncoder {
    convenience init(_ outputFormatting: OutputFormatting) {
        self.init()
        self.outputFormatting = outputFormatting
    }
}

extension URL {
    static var accounts: Self { documents("Accounts.json") }

    static func documents(_ path: String = "") -> Self {
        (isTestEnvironment ? Self.temporaryDirectory : .documentsDirectory).appending(path: path)
    }
}

extension ProcessInfo {
    var isTestEnvironment: Bool { environment["XCTestSessionIdentifier"] != nil }
}

var isTestEnvironment: Bool { ProcessInfo.processInfo.isTestEnvironment }
private let lock: NSLock = NSLock()

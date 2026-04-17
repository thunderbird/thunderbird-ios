@testable import Account
import Testing
import Foundation

struct FileManagerTests {
    @Test func writeAccounts() throws {
        let url: URL = .temporaryDirectory.appending(path: "Test.json")
        let accounts: [Account] = [
            Account(name: "Test 1"),
            Account(name: "Test 2"),
            Account(name: "Test 3")
        ]
        try FileManager.default.write(accounts, to: url)
        #expect(try FileManager.default.readAccounts(from: url).count == 3)
        #expect(try FileManager.default.readAccounts(from: url)[0].id == accounts[0].id)
        #expect(try FileManager.default.readAccounts(from: url)[1].id == accounts[1].id)
        #expect(try FileManager.default.readAccounts(from: url)[2].id == accounts[2].id)
        try FileManager.default.write(
            [
                accounts[2],
                accounts[1]
            ], to: url)
        #expect(try FileManager.default.readAccounts(from: url).count == 2)
        #expect(try FileManager.default.readAccounts(from: url)[0].id == accounts[2].id)
        #expect(try FileManager.default.readAccounts(from: url)[1].id == accounts[1].id)
        try FileManager.default.write([], to: url)
        #expect(throws: URLError(.fileDoesNotExist)) {
            try FileManager.default.readAccounts(from: url)
        }
        #expect(try FileManager.default.fileExists(at: url) == false)
    }

    @Test func fileExists() throws {
        let url: URL = .temporaryDirectory.appending(path: "Test.txt")
        let data: Data = "Test".data(using: .utf8)!
        try data.write(to: url)
        #expect(try FileManager.default.fileExists(at: url) == true)
        #expect(String(data: try Data(contentsOf: url), encoding: .utf8) == "Test")
        try? FileManager.default.removeItem(at: url)
        #expect(try FileManager.default.fileExists(at: url) == false)
    }
}

struct URLTests {
    @Test func documents() {
        #expect(URL.documents("Test.json").absoluteString.hasSuffix("/Test.json"))
        #expect(URL.documents("Test.txt") == .temporaryDirectory.appending(path: "Test.txt"))
        #expect(URL.documents() == .temporaryDirectory)
    }
}

struct ProcessInfoTests {
    @Test func isTestEnvironment() {
        #expect(ProcessInfo.processInfo.isTestEnvironment == true)
    }
}

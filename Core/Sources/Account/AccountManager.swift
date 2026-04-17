import Foundation

public typealias Accounts = AccountManager

/// Globally manage shared, persistent accounts from the SwiftUI environment.
@Observable
public class AccountManager {
    public private(set) var allAccounts: [Account] = []
    public var error: AccountError?

    /// Feature flag enables autoconfiguring new accounts using [JMAP](https://jmap.io), when supported by email provider.
    public var isJMAPAvailable: Bool = false

    public func account(for id: UUID) -> Account? {
        allAccounts.filter({ $0.id == id }).first
    }

    public func set(_ account: Account, at index: Int? = nil) {
        error = nil
        do {
            var accounts: [Account] = allAccounts
            let currentIndex: Int? = accounts.firstIndex { account.id == $0.id }
            if let currentIndex {
                accounts.remove(at: currentIndex)
            }
            let index: Int? = index ?? currentIndex  // New index OR current index OR nil (append to end)
            if let index, index < accounts.count {
                accounts.insert(account, at: index)  // Insert at new or current target index
            } else {
                accounts.append(account)  // Append to end of array
            }
            try FileManager.default.write(accounts, to: .accounts)
            allAccounts = try FileManager.default.readAccounts(from: .accounts)
        } catch {
            self.error = .fileManager(error)
        }
    }

    public func delete(_ account: Account) {
        error = nil
        do {
            try FileManager.default.write(allAccounts.filter { $0.id != account.id }, to: .accounts)
            allAccounts = try FileManager.default.readAccounts(from: .accounts)
        } catch {
            self.error = .fileManager(error)
        }
    }

    public func deleteAccounts() {
        error = nil
        do {
            try FileManager.default.write([], to: .accounts)
            allAccounts = []
        } catch {
            self.error = .fileManager(error)
        }
    }

    public init() {
        do {
            guard try FileManager.default.fileExists(at: .accounts) else { return }
            allAccounts = try FileManager.default.readAccounts(from: .accounts)
        } catch {
            self.error = .fileManager(error)
        }
    }
}

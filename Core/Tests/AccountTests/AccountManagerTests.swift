// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Account
import Testing
import Foundation
@MainActor
struct AccountManagerTests {
    @Test func set() {
        lock.lock()
        defer { lock.unlock() }
        let accounts: AccountManager = AccountManager()
        accounts.deleteAccounts()
        #expect(accounts.error == nil)
        let allAccounts: [Account] = [
            Account(name: "Example 1"),
            Account(name: "Example 2"),
            Account(name: "Example 3")
        ]
        for account in allAccounts {
            accounts.set(account)
            #expect(accounts.error == nil)
        }
        #expect(accounts.allAccounts == allAccounts)
        accounts.set(Account(id: allAccounts[1].id, name: "Example 2a"))
        #expect(accounts.allAccounts == [allAccounts[0], Account(id: allAccounts[1].id, name: "Example 2a"), allAccounts[2]])
        #expect(accounts.allAccounts[1].name == "Example 2a")
        #expect(accounts.error == nil)
        accounts.set(Account(id: allAccounts[1].id, name: "Example 2b"), at: 0)
        #expect(accounts.allAccounts == [Account(id: allAccounts[1].id, name: "Example 2b"), allAccounts[0], allAccounts[2]])
        #expect(accounts.allAccounts[0].name == "Example 2b")
        #expect(accounts.error == nil)
        accounts.set(Account(id: allAccounts[1].id, name: "Example 2"), at: 0)
        let account: Account = Account(name: "Example 4")
        accounts.set(account)
        #expect(accounts.allAccounts == [allAccounts[1], allAccounts[0], allAccounts[2], account])
        #expect(accounts.allAccounts.last?.name == "Example 4")
        #expect(accounts.error == nil)
        accounts.deleteAccounts()
    }

    @Test func delete() {
        lock.lock()
        defer { lock.unlock() }
        let accounts: AccountManager = AccountManager()
        accounts.deleteAccounts()
        #expect(accounts.error == nil)
        let allAccounts: [Account] = [
            Account(name: "Example 1", servers: [Server(.imap), Server(.smtp)]),
            Account(name: "Example 2", servers: [Server(.imap), Server(.smtp)]),
            Account(name: "Example 3", servers: [Server(.imap), Server(.smtp)])
        ]
        for account in allAccounts {
            accounts.set(account)
            #expect(accounts.error == nil)
        }
        #expect(accounts.allAccounts == allAccounts)
        accounts.delete(accounts.allAccounts[1])
        #expect(accounts.allAccounts == [allAccounts[0], allAccounts[2]])
        accounts.deleteAccounts()
    }
}

private let lock: NSLock = NSLock()

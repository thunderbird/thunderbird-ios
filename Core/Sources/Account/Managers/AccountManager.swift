// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import AuthenticationServices

/// Manages all user accounts and their persistent storage.
///
/// `AccountManager` provides a globally observable interface for adding, updating, deleting, and renewing user accounts, as well as handling their persistent storage and authorization state.
@MainActor
@Observable
public final class AccountManager {
    /// All user accounts currently managed.
    public private(set) var allAccounts: [Account] = []

    /// The most recent error encountered when managing accounts.
    public var error: AccountError?

    /// Returns the account with the given unique identifier.
    ///
    /// - Parameter id: The unique identifier for the account.
    /// - Returns: The matching `Account`, or `nil` if not found.
    public func account(for id: UUID) -> Account? {
        allAccounts.filter({ $0.id == id }).first
    }

    /// Adds or updates an account at the specified index, or appends it if no index is provided.
    ///
    /// This method replaces the existing account with the same ID if found, or appends the new account.
    /// The updated accounts list is persisted to disk.
    ///
    /// - Parameters:
    ///   - account: The account to add or update.
    ///   - index: The optional index at which to insert the account. If `nil`, replaces the current index or appends.
    /// - Throws: Updates the `error` property if writing to disk fails.
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
            allAccounts = accounts
            try FileManager.default.write(accounts, to: .accounts)
            allAccounts = try FileManager.default.readAccounts(from: .accounts)
        } catch {
            self.error = .fileManager(error)
        }
    }

    /// Returns whether there is at least one account that is currently logged in and not expired.
    ///
    /// - Returns: `true` if any account is valid and logged in; otherwise, `false`.
    public func hasLoggedInAccount() -> Bool {
        for account in allAccounts {
            if account.authorization.isExpired == false {
                return true
            }
        }
        return false
    }

    /// Deletes the specified account, removing associated authorizations and updating persistent storage.
    ///
    /// Errors encountered during deletion are recorded in the `error` property.
    ///
    /// - Parameter account: The account to delete.
    public func delete(_ account: Account) {
        error = nil
        do {
            account.deleteAuthorization()
            let updatedAccounts = allAccounts.filter { $0.id != account.id }
            try FileManager.default.write(updatedAccounts, to: .accounts)
            allAccounts = updatedAccounts
            allAccounts = try FileManager.default.readAccounts(from: .accounts)
        } catch {
            self.error = .fileManager(error)
        }
    }

    /// Deletes all accounts and removes all stored authorizations.
    ///
    /// Errors encountered during deletion are recorded in the `error` property.
    public func deleteAccounts() {
        error = nil
        do {
            URLCredentialStorage.shared.deleteAuthorizations()
            try FileManager.default.write([], to: .accounts)
            allAccounts = []
        } catch {
            self.error = .fileManager(error)
        }
    }

    /// Checks all OAuth2 accounts for expired authorizations and attempts to renew them asynchronously.
    ///
    /// Any errors during renewal are recorded in the `error` property.
    public func checkAndRenewExpirations() async {
        for account in allAccounts {
            guard account.authenticationType == .oauth2, account.authorization.isExpired,
                let refreshToken: String = account.authorization.refreshToken,
                let user: String = account.incomingServer?.username
            else {
                continue
            }
            do {
                var account: Account = account
                guard let authConfig: OAuth2.Configuration = try await account.authConfig else {
                    throw URLError(.unsupportedURL)
                }
                account.authorization = try await renewExpiredToken(
                    authConfig: authConfig,
                    refreshToken: refreshToken,
                    user: user
                )
            } catch {
                self.error = .authorization(error)
            }
        }
    }

    /// Deletes the specified account, removing associated authorizations and updating persistent storage.
    ///
    /// Errors encountered during deletion are recorded in the `error` property.
    ///
    /// - Parameters:
    ///   - authConfig: The authorization configuration for the account.
    ///   - refreshToken: The current refresh token stored for the account.
    ///   - user: The username of the account that is renewing it's token.
    ///   - retry: The number of times to retry the call if an error is returned. Defaults to 2.
    /// - Throws: Returns an error if the number of retry attempts are exhausted.
    /// - Returns: An Authorization with an updated token.
    private func renewExpiredToken(authConfig: OAuth2.Configuration, refreshToken: String, user: String, retry attempts: Int = 2) async throws -> Authorization {
        do {
            let tokenRequest: URLRequest = try .refreshToken(
                authConfig,
                refreshToken: refreshToken
            )
            let data: Data = try await URLSession.shared.data(for: tokenRequest).0
            let response: RefreshTokenResponse = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
            let token: Token = .bearer(
                response.accessToken,
                Date(timeIntervalSinceNow: TimeInterval(response.expiresIn))
            )
            return .oauth(user: user, token: token, refresh: .refresh(refreshToken))
        } catch {
            guard attempts > 0 else {
                throw error  // Retry attempts exhausted, exit
            }
            // Retry request, decrementing remaining attempts
            return try await renewExpiredToken(
                authConfig: authConfig,
                refreshToken: refreshToken,
                user: user,
                retry: attempts - 1
            )
        }
    }

    /// Initializes a new `AccountManager` instance.
    ///
    /// Attempts to load any saved accounts from persistent storage.
    public init() {
        do {
            guard try FileManager.default.fileExists(at: .accounts) else { return }
            allAccounts = try FileManager.default.readAccounts(from: .accounts)
        } catch {
            self.error = .fileManager(error)
        }
    }
}

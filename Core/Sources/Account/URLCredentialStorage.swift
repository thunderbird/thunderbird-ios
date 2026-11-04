// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Convenience methods for storing and retrieving Authorization credentials in credential storage.
extension URLCredentialStorage {
    /// Returns the Authorization for the specified user and protection space, if found.
    func authorization(for user: String, space: URLProtectionSpace = .account) -> Authorization? {
        credentials(for: space)?[user]?.authorization
    }

    /// Stores an Authorization credential with the given persistence and protection space.
    func set(authorization: Authorization, persistence: URLCredential.Persistence = .permanent, space: URLProtectionSpace = .account) {
        set(URLCredential(authorization: authorization, persistence: persistence), for: space)
    }

    /// Deletes the Authorization for a specific user within the specified protection space.
    func deleteAuthorization(for user: String, space: URLProtectionSpace = .account) {
        guard let credential: URLCredential = credentials(for: space)?[user] else { return }
        remove(credential, for: space)
    }

    /// Deletes all Authorization credentials for the given protection space.
    func deleteAuthorizations(space: URLProtectionSpace = .account) {
        for credential in (credentials(for: space) ?? [:]).values {
            remove(credential, for: space)
        }
    }
}

/// Convenience initializers and computed properties for working with Authorization.
extension URLCredential {
    /// Creates an Authorization instance from the credential’s user and password, if possible.
    var authorization: Authorization? {
        guard let user, let password else { return nil }
        return Authorization(user: user, password: password)
    }

    /// Creates a URLCredential from an Authorization and persistence setting.
    convenience init(authorization: Authorization, persistence: Persistence = .permanent) {
        self.init(user: authorization.user, password: authorization.password, persistence: persistence)
    }
}

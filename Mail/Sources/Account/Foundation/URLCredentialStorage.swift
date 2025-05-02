import Foundation

extension URLCredentialStorage {

    /// Retrieve password for a given user name and protection space.
    func password(for user: String, space: URLProtectionSpace = .account) -> String? {
        credentials(for: space)?[user]?.password
    }

    /// Set or nil password for a given user name and protection space.
    func set(_ password: String?, for user: String, space: URLProtectionSpace = .account) {
        if let password, !password.isEmpty {
            set(URLCredential(user: user, password: password, persistence: .permanent), for: space)
        } else if let credential: URLCredential = credentials(for: space)?[user] {
            remove(credential, for: space)  // Remove existing credential on nil password
        }
    }

    /// Remove all credentials for a given protection space.
    func removeCredentials(for space: URLProtectionSpace) {
        for credential in (credentials(for: space) ?? [:]).values {
            remove(credential, for: space)
        }
    }
}

import Foundation

extension URLCredentialStorage {
    func authorization(for user: String, space: URLProtectionSpace = .account) -> Authorization? {
        credentials(for: space)?[user]?.authorization
    }

    func set(authorization: Authorization, persistence: URLCredential.Persistence = .permanent, space: URLProtectionSpace = .account) {
        if !authorization.password.isEmpty {
            set(URLCredential(authorization: authorization, persistence: persistence), for: space)
        } else if let credential: URLCredential = credentials(for: space)?[authorization.user] {
            remove(credential, for: space)  // Remove existing credential on empty password
        }
    }

    func deleteAuthorizations(space: URLProtectionSpace = .account) {
        for credential in (credentials(for: space) ?? [:]).values {
            remove(credential, for: space)
        }
    }
}

extension URLCredential {
    var authorization: Authorization? {
        guard let user, let password else { return nil }
        return Authorization(user: user, password: password)
    }

    convenience init(authorization: Authorization, persistence: Persistence = .permanent) {
        self.init(user: authorization.user, password: authorization.password, persistence: persistence)
    }
}

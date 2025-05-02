import Testing
import Foundation
@testable import Account

struct URLCredentialStorageTests {
    @Test(.enabled(if: isKeychainAvailable)) func password() {
        let space: URLProtectionSpace = URLProtectionSpace(host: "com.example")
        let credential: URLCredential = URLCredential(user: "user@netscape.net", password: "essmI1-vudwic-wwanar", persistence: .forSession)
        URLCredentialStorage.shared.set(credential, for: space)
        #expect(URLCredentialStorage.shared.password(for: credential.user!, space: space) == "essmI1-vudwic-wwanar")
        URLCredentialStorage.shared.removeCredentials(for: space)
        #expect(URLCredentialStorage.shared.password(for: credential.user!, space: space) == nil)
    }

    @Test(.enabled(if: isKeychainAvailable)) func setPassword() {
        let space: URLProtectionSpace = URLProtectionSpace(host: "org.example")
        URLCredentialStorage.shared.set("zemhu8-omdRiz-zisbov", for: "user.name@icloud.com", space: space)
        #expect(URLCredentialStorage.shared.password(for: "user.name@icloud.com", space: space) == "zemhu8-omdRiz-zisbov")
        URLCredentialStorage.shared.set(nil, for: "user.name@icloud.com", space: space)
        #expect(URLCredentialStorage.shared.password(for: "user.name@icloud.com", space: space) == nil)
    }

    @Test(.enabled(if: isKeychainAvailable)) func removeCredentials() {
        let space: URLProtectionSpace = URLProtectionSpace(host: "net.example")
        URLCredentialStorage.shared.removeCredentials(for: space)
        URLCredentialStorage.shared.set(URLCredential(user: "user@netscape.net", password: "correct horse battery staple", persistence: .permanent), for: space)
        URLCredentialStorage.shared.set(URLCredential(user: "username@icloud.com", password: "abcd1234", persistence: .forSession), for: space)
        URLCredentialStorage.shared.set(URLCredential(user: "username@icloud.com", password: "abcd1234", persistence: .permanent), for: space)  // Duplicate credential
        URLCredentialStorage.shared.set(URLCredential(user: "admin@example.com", password: "gAAAAUTHtoKENb3arerJWe", persistence: .forSession), for: space)
        #expect(URLCredentialStorage.shared.credentials(for: space)?.count == 3)  // Credentials are equatable and de-duplicated by by `username`
        #expect(URLCredentialStorage.shared.credentials(for: space)?.count == 3)
        URLCredentialStorage.shared.removeCredentials(for: space)
        #expect(URLCredentialStorage.shared.credentials(for: space) == nil)
    }
}

var isKeychainAvailable: Bool {
    #if os(macOS)
    true  // Keychain only accessible (to non-hosted tests) on macOS
    #else
    false
    #endif
}

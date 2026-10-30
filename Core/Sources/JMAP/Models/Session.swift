// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Sessions include details about the data and capabilities the server can provide to the client, part of [JMAP core.](https://jmap.io/spec/rfc8620/#section-2)
public struct Session: CustomStringConvertible, Decodable, Equatable, Sendable {
    public let username: String
    public let accounts: [String: Account]
    public let primaryAccounts: [Capability.Key: String]
    public let capabilities: [Capability.Key: Capability]
    public let downloadURLTemplate: String
    public let uploadURLTemplate: String
    public let eventSourceURL: URL
    public let apiURL: URL

    public func account(_ id: String?) -> Account? {
        accounts[id ?? ""]
    }

    public func primaryAccount(for key: Capability.Key) -> Account? {
        account(primaryAccounts[key])
    }

    public func capability(for key: Capability.Key) -> Capability? {
        capabilities[key]
    }

    @discardableResult public func downloadURL(account id: String, blob: String, name: String, type: String) throws -> URL {
        guard !id.isEmpty, !blob.isEmpty, !name.isEmpty,
            let url: URL = URL(
                string: downloadURLTemplate.replacingOccurrences([
                    ("{accountId}", id),
                    ("{blobId}", blob),
                    ("{name}", name),
                    ("{type}", type)
                ]))
        else {
            throw URLError(.unsupportedURL)
        }
        return url
    }

    @discardableResult public func uploadURL(account id: String) throws -> URL {
        let uploadURLTemplate: String = uploadURLTemplate.replacingOccurrences([
            ("{accountId}", id)
        ])
        guard !id.isEmpty,
            let url: URL = URL(string: uploadURLTemplate)
        else {
            throw URLError(.unsupportedURL)
        }
        return url
    }

    // MARK: CustomStringConvertible
    public var description: String { username }

    // MARK: Decodable
    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<Key> = try decoder.container(keyedBy: Key.self)
        username = try container.decode(String.self, forKey: .username)
        accounts = try container.decode([String: Account].self, forKey: .accounts)
        let primaryAccountsDictionary: [String: String] = try container.decode([String: String].self, forKey: .primaryAccounts)
        var primaryAccounts: [Capability.Key: String] = [:]
        for key in primaryAccountsDictionary.keys {
            guard let _key: Capability.Key = Capability.Key(rawValue: key) else { continue }
            primaryAccounts[_key] = primaryAccountsDictionary[key]
        }
        self.primaryAccounts = primaryAccounts
        let capabilitiesDictionary: [String: Capability] = try container.decode([String: Capability].self, forKey: .capabilities)
        var capabilities: [Capability.Key: Capability] = [:]
        for key in capabilitiesDictionary.keys {
            guard let _key: Capability.Key = Capability.Key(rawValue: key) else { continue }
            capabilities[_key] = capabilitiesDictionary[key]
        }
        self.capabilities = capabilities
        downloadURLTemplate = try container.decode(String.self, forKey: .downloadUrl)
        uploadURLTemplate = try container.decode(String.self, forKey: .uploadUrl)
        eventSourceURL = try container.decode(URL.self, forKey: .eventSourceUrl)
        apiURL = try container.decode(URL.self, forKey: .apiUrl)
    }

    private enum Key: CodingKey {
        case username, accounts, primaryAccounts, capabilities, eventSourceUrl, uploadUrl, downloadUrl, apiUrl
    }

    // MARK: Equatable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.username == rhs.username
    }
}

private extension String {
    func replacingOccurrences(_ occurrences: [(target: Self, replacement: Self)]) -> Self {
        var string: Self = self
        for occurrence in occurrences {
            string = string.replacingOccurrences(of: occurrence.target, with: occurrence.replacement)
        }
        return string
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Accounts are a component of the JMAP ``Session`` object, part of [JMAP core.](https://jmap.io/spec/rfc8620/#section-2)
public struct Account: CustomStringConvertible, Decodable, Sendable {
    public let name: String
    public let capabilities: [Capability.Key: Capability]
    public let isReadOnly: Bool
    public let isPersonal: Bool

    public func capability(for key: Capability.Key) -> Capability? {
        capabilities[key]
    }

    // MARK: CustomStringConvertible
    public var description: String { name }

    // MARK: Decodable
    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<Key> = try decoder.container(keyedBy: Key.self)
        name = try container.decode(String.self, forKey: .name)
        let dictionary: [String: Capability] = (try? container.decode([String: Capability].self, forKey: .accountCapabilities)) ?? [:]
        var capabilities: [Capability.Key: Capability] = [:]
        for key in dictionary.keys {
            guard let _key: Capability.Key = Capability.Key(rawValue: key) else { continue }
            capabilities[_key] = dictionary[key]
        }
        self.capabilities = capabilities
        isReadOnly = try container.decode(Bool.self, forKey: .isReadOnly)
        isPersonal = try container.decode(Bool.self, forKey: .isPersonal)
    }

    private enum Key: CodingKey {
        case name, accountCapabilities, isReadOnly, isPersonal
    }
}

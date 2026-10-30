// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import Foundation

/// Extend common `EmailAddress` to decode/encode and behave like [JMAP's `EmailAddress` type.](https://jmap.io/spec/rfc8621/#section-4.1.2.3-3)
extension EmailAddress: Codable {
    public var email: String { value }
    public var name: String? { label }

    // MARK: Codable
    public func encode(to encoder: any Encoder) throws {
        var container: KeyedEncodingContainer = encoder.container(keyedBy: Key.self)
        try container.encode(value, forKey: .email)
        try container.encodeIfPresent(name, forKey: .name)
    }

    public init(from decoder: any Decoder) throws {
        if let container: SingleValueDecodingContainer = try? decoder.singleValueContainer(),
            let string: String = try? container.decode(String.self)
        {
            // Maintain backward compatibility with previous encoding as string
            self.init(stringLiteral: string)
        } else {
            let container: KeyedDecodingContainer = try decoder.container(keyedBy: Key.self)
            let email: String = try container.decode(String.self, forKey: .email)
            let name: String? = try container.decodeIfPresent(String.self, forKey: .name)
            self.init(email, label: name)
        }
    }
}

/// Extend common `EmailAddress.Group` to decode/encode and behave like [JMAP's `EmailAddressGroup` type.](https://jmap.io/spec/rfc8621/#section-4.1.2.4-3)
extension EmailAddress.Group: Codable {
    public var name: String? { label }

    func erased() -> EmailAddressProtocol {
        guard name == nil && addresses.count == 1 else {
            return self as EmailAddressProtocol
        }
        return addresses[0] as EmailAddressProtocol  // Single address can be losslessly unwrapped
    }

    // MARK: Codable
    public func encode(to encoder: any Encoder) throws {
        var container: KeyedEncodingContainer = encoder.container(keyedBy: Key.self)
        try container.encode(addresses, forKey: .addresses)
        try container.encodeIfPresent(name, forKey: .name)
    }

    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer = try decoder.container(keyedBy: Key.self)
        let name: String? = try container.decodeIfPresent(String.self, forKey: .name)
        if let email: String = try container.decodeIfPresent(String.self, forKey: .email) {
            // JMAP `address-list` can be either group or single address: https://jmap.io/spec/rfc8621/#section-4.1.2.4-7
            // Decode single address as group of one
            self.init([
                EmailAddress(email, label: name)
            ])
        } else {
            // JMAP groups are homogenous, limited to email addresses; no sub-groups
            let addresses: [EmailAddress] = try container.decode([EmailAddress].self, forKey: .addresses)
            self.init(addresses, label: name)
        }
    }
}

extension [EmailAddress.Group] {
    func erased() -> [EmailAddressProtocol] {
        map { $0.erased() }
    }
}

private enum Key: CodingKey {
    case addresses, email, name
}

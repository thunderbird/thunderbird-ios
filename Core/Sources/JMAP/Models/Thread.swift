// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Threads group replies to an ``Email`` message , part of [JMAP mail.](https://jmap.io/spec/rfc8621/#section-3)
public struct Thread: Decodable, Identifiable {
    public let emailIDs: [String]

    // MARK: Decodable
    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<Key> = try decoder.container(keyedBy: Key.self)
        emailIDs = try container.decode([String].self, forKey: .emailIds)
        id = try container.decode(String.self, forKey: .id)
    }

    private enum Key: CodingKey {
        case emailIds, id
    }

    // MARK: Identifiable
    public let id: String
}

extension Thread {
    struct GetMethod: Method {
        let ids: [String]

        init(_ accountID: String, ids: [String], id: UUID = UUID()) throws {
            guard !accountID.isEmpty else {
                throw MethodError.accountNotFound
            }
            guard !ids.isEmpty else {
                throw MethodError.invalidArguments
            }
            self.accountID = accountID
            self.ids = ids
            self.id = id
        }

        // MARK: Method
        static let name: String = "\(prefix)get"
        let accountID: String
        let id: UUID

        var object: [Any] {
            [
                Self.name,
                [
                    "accountId": accountID,
                    "ids": ids
                ],
                id.uuidString
            ]
        }
    }

    static let prefix: String = "Thread/"
}

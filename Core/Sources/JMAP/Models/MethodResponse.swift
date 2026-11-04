// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Standard ``Method`` responses with generic response components modeled, part of [JMAP core](https://jmap.io/spec/rfc8620/#section-3.4)
public protocol MethodResponse: Identifiable {
    var name: String { get }
    var id: UUID { get }
}

public struct MethodGetResponse: MethodResponse {
    public let data: Data
    public let notFound: [String]

    init(_ name: String, data: Data, notFound: [String], id: UUID) {
        self.name = name
        self.data = data
        self.notFound = notFound
        self.id = id
    }

    public func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        try JSONDecoder(date: .iso8601).decode(type, from: data)
    }

    // MARK: MethodResponse
    public let name: String
    public let id: UUID
}

public struct MethodQueryResponse: MethodResponse {
    public let ids: [String]
    public let position: Int
    public let total: Int

    init(_ name: String, ids: [String], position: Int, total: Int, id: UUID) {
        self.name = name
        self.ids = ids
        self.position = position
        self.total = total
        self.id = id
    }

    // MARK: MethodResponse
    public let name: String
    public let id: UUID
}

public struct MethodSetResponse: MethodResponse {
    public let created: [String: Any]
    public let updated: [String]
    public let destroyed: [String]
    public let notCreated: [String: SetError]
    public let notUpdated: [String: SetError]
    public let notDestroyed: [String: SetError]

    init(
        _ name: String,
        created: [String: Any],
        updated: [String],
        destroyed: [String],
        notCreated: [String: SetError],
        notUpdated: [String: SetError],
        notDestroyed: [String: SetError],
        id: UUID
    ) {
        self.name = name
        self.created = created
        self.updated = updated
        self.destroyed = destroyed
        self.notCreated = notCreated
        self.notUpdated = notUpdated
        self.notDestroyed = notDestroyed
        self.id = id
    }

    // MARK: MethodResponse
    public let name: String
    public let id: UUID
}

public struct MethodEchoResponse: MethodResponse {
    init(_ name: String, id: UUID) {
        self.name = name
        self.id = id
    }

    // MARK: MethodResponse
    public let name: String
    public let id: UUID
}

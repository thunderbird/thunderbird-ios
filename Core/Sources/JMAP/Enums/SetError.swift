// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Errors encountered during a `set` ``Method`` operation, returned exclusively in ``MethodResponse``
public enum SetError: String, CaseIterable, CustomStringConvertible, Error, Identifiable {
    case forbidden
    case invalidPatch, invalidProperties
    case mailboxHasEmail
    case notFound
    case overQuota
    case rateLimit
    case requestTooLarge
    case singleton
    case stateMismatch
    case tooLarge
    case willDestroy

    init?(_ value: Any) {
        if let data: Data = value as? Data,
            let value: Any = try? JSONSerialization.jsonObject(with: data),
            let error: Self = Self(value)
        {
            self = error
        } else if let value: [String: Any] = value as? [String: Any],
            let error: Self = Self(rawValue: value["type"] as? String ?? "")
        {
            self = error
        } else if let error: Self = Self(rawValue: value as? String ?? "") {
            self = error
        } else {
            return nil
        }
    }

    // MARK: CustomStringConvertible
    public var description: String {
        switch self {
        case .forbidden: "Forbidden"
        case .invalidPatch: "Invalid patch"
        case .invalidProperties: "Invalid properties"
        case .mailboxHasEmail: "Mailbox has email"
        case .notFound: "Not found"
        case .overQuota: "Over quota"
        case .rateLimit: "Rate limit"
        case .requestTooLarge: "Request too large"
        case .singleton: "Singleton"
        case .stateMismatch: "State mismatch"
        case .tooLarge: "Too large"
        case .willDestroy: "Will destroy"
        }
    }

    // MARK: Identifiable
    public var id: String { rawValue }
}

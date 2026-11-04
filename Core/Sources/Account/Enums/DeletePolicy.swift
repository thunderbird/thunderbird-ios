// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A policy describing how messages should be deleted or retained.
///
/// Policies include deleting after a number of days, deleting upon user action, marking as read, or never deleting.
public enum DeletePolicy: Codable, CustomStringConvertible, Equatable, Hashable, RawRepresentable, Sendable {
    case after(days: Int = 7), onDelete, markAsRead, never

    // MARK: CustomStringConvertible
    /// A human-readable description of the policy.
    public var description: String { rawValue }

    // MARK: RawRepresentable
    /// The string representation of the policy used for persistence.
    public var rawValue: String {
        switch self {
        case .after(let days): "after \(days) days"
        case .onDelete: "on delete"
        case .markAsRead: "mark as read"
        case .never: "never"
        }
    }

    /// Creates a delete policy from a raw string value.
    ///
    /// - Parameter rawValue: The string to parse. Supported values include `"on delete"`, `"mark as read"`, `"never"`, and the pattern `"after <days> days"`.
    /// - Returns: An initialized `DeletePolicy` if parsing succeeds; otherwise `nil`.
    public init?(rawValue: String) {
        switch rawValue {
        case "on delete": self = .onDelete
        case "mark as read": self = .markAsRead
        case "never": self = .never
        default:
            let components: [String] = rawValue.components(separatedBy: " ")
            guard components.count == 3,
                components.first == "after",
                components.last == "days",
                let days: Int = Int(components[1]),
                days >= 0
            else {
                return nil
            }
            self = .after(days: days)
        }
    }
}

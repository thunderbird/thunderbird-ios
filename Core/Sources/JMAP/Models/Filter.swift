// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Filters narrow the returned responses when querying ``Email``, part of [JMAP core.](https://jmap.io/spec/rfc8620/#section-5.5)
public struct Filter: CustomStringConvertible {
    public protocol Condition: CustomStringConvertible {
        var key: String { get }
        var value: Any { get }
    }

    public enum Operator: String, CaseIterable, CustomStringConvertible {
        case and = "AND"
        case or = "OR"
        case not = "NOT"

        // MARK: CustomStringConvertible
        public var description: String { rawValue }
    }

    public let conditions: [Condition]
    public let `operator`: Operator

    public init(_ conditions: [Condition], `operator`: Operator = .or) {
        self.conditions = conditions
        self.operator = `operator`
    }

    var object: [String: Any] {
        [
            "conditions": conditions.map { $0.object },
            "operator": "\(self.operator)"
        ]
    }

    // MARK: CustomStringConvertible
    public var description: String {
        "Filter: \(conditions.map { "\($0)" }.joined(separator: "\(self.operator) "))"
    }
}

extension Filter.Condition {
    public var object: [String: Any] {
        [
            key: value
        ]
    }

    // MARK: CustomStringConvertible
    public var description: String { "\(key): \(value)" }
}

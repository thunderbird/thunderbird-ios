// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Foundation

/// Configure ``Server`` with credentials or token for appropriate HTTP authentication scheme.
public enum Authorization: CustomStringConvertible, Equatable, Sendable {
    case basic(_ user: String, _ password: String)
    case bearer(_ token: String)

    public static var empty: Self { .bearer("") }

    public var label: String {
        switch self {
        case .basic: "basic"
        case .bearer: "bearer"
        }
    }

    public var isEmpty: Bool {
        switch self {
        case .basic: token == "Og=="
        case .bearer: token.isEmpty
        }
    }

    var token: String {
        switch self {
        case .basic(let user, let password): "\(user):\(password)".base64Encoded()
        case .bearer(let token): token
        }
    }

    // MARK: CustomStringConvertible
    public var description: String { "\(label.capitalized) \(token)" }

    // MARK: Equatable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.description == rhs.description
    }
}

extension String {
    func base64Encoded() -> Self {
        data(using: .utf8)!.base64EncodedString()
    }
}

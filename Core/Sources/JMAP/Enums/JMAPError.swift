// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// ``JMAPClient`` throws `JMAPError`.
public enum JMAPError: Error, CustomStringConvertible, Equatable {
    case method(_ error: MethodError)
    case request(_ error: RequestError)
    case set(_ error: SetError)
    /// Wrap HTTP and other underlying system errors.
    case underlying(_ error: Error)

    // Convenience convert any Error to `JMAPError`
    init(_ error: Error) {
        if let error: MethodError = error as? MethodError {
            self = .method(error)
        } else if let error: SetError = error as? SetError {
            self = .set(error)
        } else if let error: Self = error as? Self {
            self = error
        } else {
            self = .underlying(error)
        }
    }

    // MARK: CustomStringConvertible
    public var description: String {
        switch self {
        case .method(let error): "Method error: \(error)"
        case .request(let error): "Request error: \(error)"
        case .set(let error): "Set error: \(error)"
        case .underlying(let error): "Underlying error: \(error.localizedDescription)"
        }
    }

    // MARK: Equatable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.description == rhs.description
    }
}

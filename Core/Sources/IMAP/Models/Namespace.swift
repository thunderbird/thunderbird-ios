// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Merged  `NIOIMAPCore.NamespaceResponse` and `NamespaceDescription` model
public struct Namespace: Hashable, Sendable {
    public enum Scope: String, CaseIterable, CustomStringConvertible, Sendable {
        case user, shared, other

        // MARK: CustomStringConvertible
        public var description: String { rawValue }
    }

    public let scope: Scope
    public let delimiter: Character?
    public let prefix: String

    public init(_ scope: Scope, delimiter: Character? = .delimiter, prefix: String = "") {
        self.scope = scope
        self.delimiter = delimiter
        self.prefix = prefix
    }
}

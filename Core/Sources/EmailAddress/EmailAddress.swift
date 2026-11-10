// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A type that can provide one or more concrete `EmailAddress` values.
///
/// Conforming types expose their underlying addresses via the `addresses` collection.
public protocol EmailAddressProtocol: Sendable {
    var addresses: [EmailAddress] { get }
}

/// Shared email address model suitable for IMAP, JMAP and SMTP
public struct EmailAddress: CustomStringConvertible, EmailAddressProtocol, ExpressibleByStringLiteral, Hashable, Identifiable, Sendable {
    /// The raw email address value (e.g., "name@example.com").
    public let value: String

    /// An optional display name associated with the address.
    public let label: String?

    /// The host/domain portion of the email address.
    ///
    /// - Returns: The domain if it can be parsed; otherwise, `nil`.
    public var host: String? {
        URL(string: "http://\(value.components(separatedBy: "@").last!)")?.host()
    }

    /// The local/user portion of the email address.
    ///
    /// - Returns: The local part if the address contains `@`; otherwise, `nil`.
    public var local: String? {
        value.contains("@") ? value.components(separatedBy: "@").dropLast().joined(separator: "@") : nil
    }

    /// Indicates whether the value appears to be a valid email address.
    ///
    /// - Returns: `true` if both the local and host parts are non-empty; otherwise, `false`.
    public var isEmailAddress: Bool { !(host ?? "").isEmpty && !(local ?? "").isEmpty }

    /// Initializes an email address from a raw string and optional label.
    ///
    /// The initializer accepts both plain addresses (e.g., "name@example.com") and display-name formats (e.g., "Example Name <name@example.com>").
    ///
    /// - Parameters:
    ///   - value: The raw string to parse.
    ///   - label: An optional display label. If absent and the string uses display-name format, the name portion is used.
    public init(_ value: String, label: String? = nil) {
        let components: [String] = value.trimmed().components(separatedBy: "<")
        if components.count == 2, components[1].hasSuffix(">") {  // "Example Name <name@example.com>"
            self.value = "\(components[1].dropLast())"
            self.label = label ?? components[0].trimmed()
        } else {
            let label: String = label?.trimmed() ?? ""
            self.value = components[0].trimmed()
            self.label = !label.isEmpty ? label : nil
        }
    }

    /// Required for `CustomStringConvertible` conformance.
    public var description: String { !(label ?? "").isEmpty ? "\(label!) <\(value)>" : value }

    /// Required for `EmailAddressProtocol` conformance.
    public var addresses: [Self] { [self] }

    /// Required for `ExpressibleByStringLiteral` conformance.
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }

    /// Required for `Identifiable` conformance.
    public var id: String { value }
}

/// Extends `EmailAddress` with Group and list support.
///
/// Adds the `EmailAddress.Group` type which can aggregate multiple addresses and other groups.
extension EmailAddress {

    /// Shared email address group/list model suitable for IMAP and JMAP
    public struct Group: EmailAddressProtocol, Equatable, Sendable {
        public let label: String?
        public let email: [EmailAddressProtocol]

        /// Initializes an email address group from an array of `EmailAddressProtocl` and optional label.
        ///
        /// - Parameters:
        ///   - email: The array of `EmailAddressProtocol` to create the group with.
        ///   - label: An optional display label. If absent and the string uses display-name format, the name portion is used.
        public init(_ email: [EmailAddressProtocol], label: String? = nil) {
            let label: String = label?.trimmed() ?? ""
            self.label = !label.isEmpty ? label : nil
            self.email = email
        }

        /// Required for `EmailAddressProtocol` conformance.
        public var addresses: [EmailAddress] { email.flatMap { $0.addresses } }

        /// Required for `Equatable` conformance.
        public static func == (lhs: Self, rhs: Self) -> Bool {
            // Equality ignores labels, positions and grouping
            lhs.addresses.map({ $0.id }).sorted() == rhs.addresses.map({ $0.id }).sorted()
        }
    }
}

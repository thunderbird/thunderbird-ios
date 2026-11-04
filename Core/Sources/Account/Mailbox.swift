// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A common mailbox model that unifies JMAP and IMAP concepts.
///
/// The `Mailbox` type bridges server-specific mailbox representations into a
/// single, lightweight value used by the Account layer and UI. It exposes a
/// consistent set of properties such as display `name`, server-derived `role`,
/// access `rights`, and message counts.
///
/// This file also contains helpers to construct a `Mailbox` from IMAP and JMAP
/// types and heuristics for mapping IMAP paths to JMAP-like roles and rights.
public struct Mailbox: CustomStringConvertible, Hashable, Identifiable {
    /// The standardized mailbox role adopted from `JMAP.Mailbox.Role`.
    ///
    /// Roles identify well-known folders such as `inbox`, `sent`, or `trash`.
    public typealias Role = JMAP.Mailbox.Role

    /// The mailbox access rights adopted from `JMAP.Mailbox.Rights`.
    ///
    /// Rights describe allowed actions such as renaming and deletion.
    public typealias Rights = JMAP.Mailbox.Rights

    public let role: Role?
    public let rights: Rights
    public var name: String
    public var isSubscribed: Bool
    public let unreadEmails: Int?
    public let totalEmails: Int?
    public let id: String

    /// Required for `CustomStringConvertible` conformance.
    public var description: String {
        return name
    }

    /// Creates a new mailbox value.
    ///
    /// - Parameters:
    ///   - name: The display name of the mailbox.
    ///   - role: The standardized role, when available.
    ///   - rights: The access rights for this mailbox. Defaults to an empty `Rights`.
    ///   - isSubscribed: Whether the mailbox is subscribed. Defaults to `true`.
    ///   - unreadEmails: The unread message count, if known.
    ///   - totalEmails: The total message count, if known.
    ///   - id: A stable identifier to use for this mailbox. If `nil`, a UUID will be generated.
    ///
    /// - Discussion: When no `id` is provided, a short UUID string is assigned so the
    ///   mailbox can be identified across UI updates within the app session.
    public init(
        _ name: String,
        role: Role? = nil,
        rights: Rights = Rights(),
        isSubscribed: Bool = true,
        unreadEmails: Int? = nil,
        totalEmails: Int? = nil,
        id: String? = nil
    ) {
        self.name = name
        self.role = role
        self.rights = rights
        self.isSubscribed = isSubscribed
        self.unreadEmails = unreadEmails
        self.totalEmails = totalEmails
        self.id = id ?? UUID().uuidString.prefix(8).lowercased()
    }
}

/// Convenience initializers for creating generic `Mailbox` values from
/// IMAP and JMAP counterparts.
extension Mailbox {
    /// Creates a `Mailbox` from an IMAP mailbox and optional status.
    ///
    /// - Parameters:
    ///   - mailbox: A tuple containing the IMAP mailbox and its optional status.
    ///   - id: An optional identifier to transfer across re-LIST operations.
    ///
    /// - Discussion: IMAP does not provide stable mailbox identifiers. A UUID is
    ///   generated and transferred during the same app session to provide stability.
    init(_ mailbox: (IMAP.Mailbox, IMAP.Mailbox.Status?), id: String? = nil) {
        self.name = mailbox.0.path.name.description
        self.role = mailbox.0.path.suggestedRole  // Map JMAP mailbox roles to IMAP mailboxes
        self.rights = mailbox.0.path.suggestedRights  // Shim mailbox permissions until IMAP MYRIGHTS implemented
        self.isSubscribed = !mailbox.0.attributes.filter({ $0 == .subscribed }).isEmpty
        self.unreadEmails = mailbox.1?.unseenCount
        self.totalEmails = mailbox.1?.messageCount
        self.id = id ?? UUID().uuidString(1)  // Transfer UUID or autogenenrate new one
    }

    /// Creates a `Mailbox` from a JMAP mailbox value.
    ///
    /// - Parameter mailbox: The JMAP mailbox to map from.
    init(_ mailbox: JMAP.Mailbox) {
        self.name = mailbox.name
        self.role = mailbox.role
        self.rights = mailbox.rights
        self.isSubscribed = mailbox.isSubscribed
        self.unreadEmails = mailbox.unreadEmails
        self.totalEmails = mailbox.totalEmails
        self.id = mailbox.id
    }
}

/// Convenience properties for deriving rights and roles from IMAP mailbox paths.
///
/// These helpers provide best-effort mappings to JMAP-like semantics when IMAP
/// servers do not expose full metadata (e.g., `MYRIGHTS`).
extension IMAP.Mailbox.Path {

    /// A best-effort estimate of mailbox rights based on role and Gmail path prefix.
    ///
    /// Gmail internal folders (e.g., "[Gmail]/...") are treated as non-renamable and
    /// non-deletable, while other folders are editable when no role is implied.
    var suggestedRights: Mailbox.Rights {
        // Gmail allows renaming and deleting label mailboxes, but
        // [Gmail]-prefixed internal folders can't be modified.
        if let pathSeparator, name.description.components(separatedBy: "\(pathSeparator)")[0].hasPrefix("[Gmail]") {
            return Mailbox.Rights(mayRename: false, mayDelete: false)
        }

        // IMAP mailbox rights all default to true if MYRIGHTS is
        // unavailable from provider:
        // https://www.rfc-editor.org/info/rfc8440/
        return Mailbox.Rights(mayRename: suggestedRole == nil, mayDelete: suggestedRole == nil)
    }

    /// Attempts to infer a standardized mailbox role from the last path component.
    var suggestedRole: Mailbox.Role? {
        let rawValue: String = lastPathComponent.lowercased().components(separatedBy: .whitespaces)[0]
        if let role: Mailbox.Role = Mailbox.Role(rawValue: rawValue) {
            return role
        } else if rawValue.hasPrefix("archived") {
            return .archive
        } else if rawValue.hasPrefix("spam") || rawValue.hasPrefix("junk") || rawValue.hasPrefix("bulk") {
            return .junk
        } else if rawValue.hasPrefix("deleted") {
            return .trash
        } else if rawValue.hasPrefix("draft") {
            return .drafts
        } else {
            return nil
        }
    }
}

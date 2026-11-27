// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A model representing one row in an account's folder tree: a mailbox, or a parent that only groups others.
public struct Folder: CustomStringConvertible, Hashable, Identifiable {
    /// The display name of the folder: the last level of its path.
    public let name: String?
    /// Full path including parent folders. For a mailbox this is the name the server knows it by.
    public let path: String?
    /// Number of unread emails in this folder.
    public let unreadEmails: Int?
    /// Total emails in this folder.
    public let totalEmails: Int?
    /// Unique identifier for the folder.
    public let id: String
    /// The mailbox this folder shows; `nil` for a placeholder.
    ///
    /// A placeholder stands in for a parent the server didn't list, so that its subfolders have somewhere to go. It
    /// has no mail of its own and can't be opened.
    public let mailbox: Mailbox?
    /// Immediate child folders.
    public var subfolders: [Folder] = []

    /// Whether the folder is a parent the server didn't list, with no mailbox behind it.
    public var isPlaceholder: Bool { mailbox == nil }

    /// Creates a Folder from explicit properties.
    public init(
        name: String?,
        path: String?,
        unreadEmails: Int?,
        totalEmails: Int?,
        id: String?,
        mailbox: Mailbox?,
        subfolders: [Folder] = []
    ) {
        self.name = name
        self.path = path
        self.unreadEmails = unreadEmails
        self.totalEmails = totalEmails
        self.id = id ?? UUID().uuidString(1)
        self.mailbox = mailbox
        self.subfolders = subfolders
    }

    // MARK: CustomStringConvertible
    /// A string summary of this folder.
    public var description: String {
        return "\(unreadEmails ?? 0)/\(totalEmails ?? 0) | \(name ?? "unnamed folder") | Subfolders: \(subfolders.count)"
    }
}

public extension Folder {
    /// Recursively counts unread emails in this folder and all subfolders.
    func aggregatedUnreadCount() -> Int {
        var total = unreadEmails ?? 0
        for subfolder in subfolders {
            total += subfolder.aggregatedUnreadCount()
        }
        return total
    }
}

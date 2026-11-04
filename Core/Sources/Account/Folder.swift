// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A model representing a mail folder within a mailbox, including subfolders and message counts.
public struct Folder: CustomStringConvertible, Hashable, Identifiable {
    /// The display name of the folder.
    public let name: String?
    /// Full path including parent mailbox.
    public let path: String?
    /// Number of unread emails in this folder.
    public let unreadEmails: Int?
    /// Total emails in this folder.
    public let totalEmails: Int?
    /// Unique identifier for the folder.
    public let id: String
    /// The parent Mailbox this folder belongs to.
    public let mailbox: Mailbox
    /// Immediate child folders.
    public var subfolders: [Folder] = []

    /// Creates a Folder from explicit properties.
    public init(
        name: String?,
        path: String?,
        unreadEmails: Int?,
        totalEmails: Int?,
        id: String?,
        mailbox: Mailbox,
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

    /// Creates a Folder from a Mailbox instance.
    init(from mailbox: Mailbox) {
        self.name = mailbox.name.components(separatedBy: "/").last
        self.path = mailbox.name
        self.unreadEmails = mailbox.unreadEmails
        self.totalEmails = mailbox.totalEmails
        self.id = UUID().uuidString
        self.mailbox = mailbox
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

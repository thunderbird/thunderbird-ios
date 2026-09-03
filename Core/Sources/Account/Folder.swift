// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Common folder model representing a folder within a given mailbox.
public struct Folder: CustomStringConvertible, Hashable, Identifiable {
    public let name: String?
    /// Path represents the full path of the folder including the parent mailbox
    public let path: String?
    public let unreadEmails: Int?
    public let totalEmails: Int?
    public let id: String
    public let mailbox: Mailbox
    public var subfolders: [Folder] = []

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

    init(from mailbox: Mailbox) {
        self.name = mailbox.name.components(separatedBy: "/").last
        self.path = mailbox.name
        self.unreadEmails = mailbox.unreadEmails
        self.totalEmails = mailbox.totalEmails
        self.id = UUID().uuidString
        self.mailbox = mailbox
    }

    // MARK: CustomStringConvertible
    public var description: String {
        return "\(unreadEmails ?? 0)/\(totalEmails ?? 0) | \(name ?? "unnamed folder") | Subfolders: \(subfolders.count)"
    }
}

public extension Folder {
    func aggregatedUnreadCount() -> Int {
        var total = unreadEmails ?? 0
        for subfolder in subfolders {
            total += subfolder.aggregatedUnreadCount()
        }
        return total
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Manages and organizes folders for a given Account.
@Observable
public final class FolderManager {
    /// The Account for which folders are managed.
    public let account: Account
    /// Top-level folders for the account.
    public var folders: [Folder] = []
    /// The character between the levels of a mailbox path, used for every mailbox in the account.
    ///
    /// It starts as `/` and changes when a refresh brings a mailbox that reports another.
    public private(set) var pathSeparator: Character = "/"

    /// Initializes the FolderManager with an Account.
    ///
    /// - Parameter account: The `Account` to initialize the manger with.
    public init(account: Account) {
        self.account = account
    }

    /// Finds a folder by its unique identifier.
    ///
    /// - Parameter id: The unique id of the Folder to be found.
    /// - Returns: A `Folder` with a matching id, if one exists.
    public func folderForID(_ id: String) -> Folder? {
        folders.filter { $0.id == id }.first
    }

    /// Finds a folder by its name.
    ///
    /// - Parameter name: The name of the Folder to be found.
    /// - Returns: The first `Folder` with a matching name, if one exists.
    public func folderForName(_ name: String) -> Folder? {
        folders.filter { $0.name == name }.first
    }

    /// Finds a folder by its path.
    ///
    /// - Parameter path: The path of the Folder to be found.
    /// - Returns: The first `Folder` with a matching path, if one exists.
    public func folderForPath(_ path: String) -> Folder? {
        folders.filter { $0.path == path }.first
    }

    /// Replace the account's folders with a tree built from its mailboxes.
    ///
    /// The tree is rebuilt from the flat list every time, so refreshing with the same mailboxes gives the same
    /// folders, each with the same `id`. See ``tree(from:separator:maxDepth:)`` for how mailboxes are nested.
    ///
    /// - Parameter mailboxes: Every mailbox in the account, in the order the server listed them.
    /// - Important: One separator is used for the whole account: that of the first mailbox that has one. If no
    ///   mailbox has one, the separator from the last refresh is kept.
    public func refreshFolders(mailboxes: [Mailbox]) async {
        if let pathSeparator: Character = mailboxes.lazy.compactMap(\.pathSeparator).first {
            self.pathSeparator = pathSeparator
        }
        folders = Self.tree(from: mailboxes, separator: pathSeparator)
    }

    /// Arrange a flat list of mailboxes into a tree of folders, by splitting each mailbox's name into path levels.
    ///
    /// The rules are those of thunderbird-android's `GetDisplayTreeFolder`, so both apps show the same tree:
    ///
    /// - Folders at each level keep the order in which the server first listed them.
    /// - A parent that isn't itself in the list becomes a placeholder: a folder with no mailbox.
    /// - A name with more than `maxDepth` levels keeps that many, and the rest become one folder named with the
    ///   remaining path. With the default of 2, `A/B/C/D` is `A`, then `B`, then `C/D`.
    /// - An empty level, as in `A//B`, is shown as `(Unnamed)`.
    /// - If a name is listed twice, the first mailbox is kept.
    ///
    /// - Parameters:
    ///   - mailboxes: The mailboxes to arrange, in the order the server listed them.
    ///   - separator: The character between the levels of a mailbox name.
    ///   - maxDepth: How many leading levels of a name each become a folder of their own.
    /// - Returns: The top-level folders, each holding its subfolders.
    static func tree(from mailboxes: [Mailbox], separator: Character = "/", maxDepth: Int = 2) -> [Folder] {
        tree(
            from: mailboxes.map { (levels($0.name, separator: separator, maxDepth: maxDepth), $0) },
            separator: separator,
            parentPath: ""
        )
    }

    // Folders for one level of the tree: one for each distinct first level among the paths, in first-seen order
    private static func tree(from paths: [(levels: [String], mailbox: Mailbox)], separator: Character, parentPath: String) -> [Folder] {
        var names: [String] = []
        var groups: [String: [(levels: [String], mailbox: Mailbox)]] = [:]
        for path in paths {
            let name: String = path.levels[0]
            if groups[name] == nil {
                names.append(name)
            }
            groups[name, default: []].append(path)
        }
        return names.map { name in
            let group: [(levels: [String], mailbox: Mailbox)] = groups[name]!
            let path: String = parentPath.isEmpty ? name : "\(parentPath)\(separator)\(name)"
            let mailbox: Mailbox? = group.first { $0.levels.count == 1 }?.mailbox  // Otherwise a placeholder
            return Folder(
                name: name,
                path: mailbox?.name ?? path,
                unreadEmails: mailbox?.unreadEmails,
                totalEmails: mailbox?.totalEmails,
                id: mailbox?.id ?? "placeholder:\(path)",  // Same after every refresh
                mailbox: mailbox,
                subfolders: tree(
                    from: group.filter { $0.levels.count > 1 }.map { (Array($0.levels.dropFirst()), $0.mailbox) },
                    separator: separator,
                    parentPath: path
                )
            )
        }
    }

    // Split a mailbox name into the levels it is shown at; anything past `maxDepth` levels stays joined as the last
    private static func levels(_ name: String, separator: Character, maxDepth: Int) -> [String] {
        let levels: [String] = name.split(separator: separator, omittingEmptySubsequences: false).map {
            $0.trimmingCharacters(in: .whitespaces).isEmpty ? "(Unnamed)" : String($0)
        }
        guard levels.count > maxDepth else {
            return levels
        }
        return levels.prefix(maxDepth) + [levels.dropFirst(maxDepth).joined(separator: "\(separator)")]
    }
}

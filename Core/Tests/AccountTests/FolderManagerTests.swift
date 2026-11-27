// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Account
import Testing

// `//Source:` marks a case that thunderbird-android also tests, pinned to the commit it was read at. Its
// `GetDisplayTreeFolder` builds the drawer's tree by the same rules; the cases were written for this type, not copied.
//
// Trees are compared as outlines: one line per folder, indented two spaces per level, with `*` after a placeholder.
struct FolderManagerTests {

    // MARK: Nesting

    //Expect: Keep every mailbox at the top level, in the order the server listed them.
    //Case: When no mailbox name has more than one level.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/214eee3d058b16ac9f9d3bcee3bb885ab6392d97/feature/navigation/drawer/dropdown/src/test/kotlin/net/thunderbird/feature/navigation/drawer/dropdown/domain/usecase/GetDisplayTreeFolderTest.kt#L21
    @Test func tree_keepsServerOrderAtTopLevel_whenMailboxesAreFlat() {
        // Arrange
        let input: [Mailbox] = mailboxes("INBOX", "Sent", "Archive")
        let expected = ["INBOX", "Sent", "Archive"]

        // Act
        let actual = outline(FolderManager.tree(from: input))

        // Assert
        #expect(actual == expected)
    }

    //Expect: Put the mailbox under its parent.
    //Case: When a mailbox name has two levels and its parent is listed.
    @Test func tree_nestsMailboxUnderParent_whenNameHasTwoLevels() {
        // Arrange
        let input: [Mailbox] = mailboxes("INBOX", "A", "A/B")
        let expected = ["INBOX", "A", "  B"]

        // Act
        let actual = outline(FolderManager.tree(from: input))

        // Assert
        #expect(actual == expected)
    }

    //Expect: Show each mailbox once, under its parent.
    //Case: When a mailbox has both a parent and a subfolder.
    @Test func tree_showsEachMailboxOnce_whenNameHasThreeLevels() {
        // Arrange
        let input: [Mailbox] = mailboxes("INBOX", "A", "A/B", "A/B/C", "Sent")
        let expected = ["INBOX", "A", "  B", "    C", "Sent"]

        // Act
        let actual = outline(FolderManager.tree(from: input))

        // Assert
        #expect(actual == expected)
    }

    //Expect: Add a placeholder for the parent, holding both mailboxes.
    //Case: When two mailboxes share a parent that the server didn't list.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/214eee3d058b16ac9f9d3bcee3bb885ab6392d97/feature/navigation/drawer/dropdown/src/test/kotlin/net/thunderbird/feature/navigation/drawer/dropdown/domain/usecase/GetDisplayTreeFolderTest.kt#L309
    @Test func tree_addsPlaceholderParent_whenParentIsNotListed() {
        // Arrange
        let input: [Mailbox] = mailboxes("folderLevel1/folderLevel2_1", "folderLevel1/folderLevel2_2")
        let expected = ["folderLevel1*", "  folderLevel2_1", "  folderLevel2_2"]

        // Act
        let actual = outline(FolderManager.tree(from: input, maxDepth: 3))

        // Assert
        #expect(actual == expected)
    }

    //Expect: Keep the first two levels and name the last folder with the rest of the path.
    //Case: When a mailbox name has more levels than the maximum depth.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/214eee3d058b16ac9f9d3bcee3bb885ab6392d97/feature/navigation/drawer/dropdown/src/test/kotlin/net/thunderbird/feature/navigation/drawer/dropdown/domain/usecase/GetDisplayTreeFolderTest.kt#L369
    @Test func tree_joinsLevelsPastMaximumDepth_whenNameIsDeeper() {
        // Arrange
        let input: [Mailbox] = mailboxes("level1/level2/level3", "level1/level2/level3/level4")
        let expected = ["level1*", "  level2*", "    level3", "    level3/level4"]

        // Act
        let actual = outline(FolderManager.tree(from: input, maxDepth: 2))

        // Assert
        #expect(actual == expected)
    }

    //Expect: Show each empty level as `(Unnamed)`.
    //Case: When mailbox names are empty or have nothing between separators.
    //Source: https://github.com/thunderbird/thunderbird-android/blob/214eee3d058b16ac9f9d3bcee3bb885ab6392d97/feature/navigation/drawer/dropdown/src/test/kotlin/net/thunderbird/feature/navigation/drawer/dropdown/domain/usecase/GetDisplayTreeFolderTest.kt#L132
    @Test func tree_namesEmptyLevelsUnnamed_whenNamesAreMalformed() {
        // Arrange
        let input: [Mailbox] = mailboxes("Inbox", "", "///", "valid1///valid2")
        let expected = [
            "Inbox",
            "(Unnamed)",
            "  (Unnamed)*",
            "    (Unnamed)/(Unnamed)",
            "valid1*",
            "  (Unnamed)*",
            "    (Unnamed)/valid2"
        ]

        // Act
        let actual = outline(FolderManager.tree(from: input, maxDepth: 2))

        // Assert
        #expect(actual == expected)
    }

    //Expect: Keep the first mailbox and drop the repeat.
    //Case: When the server lists the same name twice.
    @Test func tree_keepsFirstMailbox_whenNameIsListedTwice() {
        // Arrange
        let input: [Mailbox] = [Mailbox("Junk", id: "first"), Mailbox("Junk", id: "second")]
        let expected = ["first"]

        // Act
        let actual = FolderManager.tree(from: input).map(\.id)

        // Assert
        #expect(actual == expected)
    }

    // MARK: Separator

    //Expect: Nest on the separator the server reported.
    //Case: When mailboxes report `.` as their separator.
    @Test func refreshFolders_nestsOnReportedSeparator_whenSeparatorIsDot() async {
        // Arrange
        let manager: FolderManager = FolderManager(account: Account("alice@example.com"))
        let input: [Mailbox] = mailboxes("INBOX", "Work", "Work.Q1", "Work.Q1.Jan", separator: ".")
        let expected = ["INBOX", "Work", "  Q1", "    Jan"]

        // Act
        await manager.refreshFolders(mailboxes: input)
        let actual = outline(manager.folders)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Nest on `/`.
    //Case: When no mailbox reports a separator.
    @Test func refreshFolders_nestsOnSlash_whenNoMailboxReportsSeparator() async {
        // Arrange
        let manager: FolderManager = FolderManager(account: Account("alice@example.com"))
        let input: [Mailbox] = mailboxes("Work", "Work/Q1", "Work.Q2")
        let expected = ["Work", "  Q1", "Work.Q2"]

        // Act
        await manager.refreshFolders(mailboxes: input)
        let actual = outline(manager.folders)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Use the first reported separator for every mailbox.
    //Case: When mailboxes in one account report different separators.
    @Test func refreshFolders_usesFirstReportedSeparator_whenMailboxesDisagree() async {
        // Arrange
        let manager: FolderManager = FolderManager(account: Account("alice@example.com"))
        let input: [Mailbox] = [
            Mailbox("INBOX"),
            Mailbox("Work.Q1", pathSeparator: "."),
            Mailbox("Shared/Team", pathSeparator: "/")
        ]
        let expected = ["INBOX", "Work*", "  Q1", "Shared/Team"]

        // Act
        await manager.refreshFolders(mailboxes: input)
        let actual = outline(manager.folders)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Keep the separator from the earlier refresh.
    //Case: When a later refresh brings no mailbox that reports one.
    @Test func refreshFolders_keepsEarlierSeparator_whenLaterRefreshReportsNone() async {
        // Arrange
        let manager: FolderManager = FolderManager(account: Account("alice@example.com"))
        await manager.refreshFolders(mailboxes: mailboxes("Work.Q1", separator: "."))
        let expected: Character = "."

        // Act
        await manager.refreshFolders(mailboxes: mailboxes("Work.Q1"))
        let actual = manager.pathSeparator

        // Assert
        #expect(actual == expected)
    }

    // MARK: Refreshing

    //Expect: Show the same tree as after the first refresh.
    //Case: When the same mailboxes are refreshed a second time.
    @Test func refreshFolders_replacesFolders_whenRefreshedTwice() async {
        // Arrange
        let manager: FolderManager = FolderManager(account: Account("alice@example.com"))
        let input: [Mailbox] = mailboxes("INBOX", "A", "A/B", "A/B/C", "A/B/C/D", "Sent")
        let expected = ["INBOX", "A", "  B", "    C", "    C/D", "Sent"]

        // Act
        await manager.refreshFolders(mailboxes: input)
        await manager.refreshFolders(mailboxes: input)
        let actual = outline(manager.folders)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Give every folder, placeholders included, the `id` it had before.
    //Case: When the same mailboxes are refreshed a second time.
    @Test func refreshFolders_keepsFolderIDs_whenRefreshedTwice() async {
        // Arrange
        let manager: FolderManager = FolderManager(account: Account("alice@example.com"))
        let input: [Mailbox] = mailboxes("INBOX", "A/B", "A/C")
        await manager.refreshFolders(mailboxes: input)
        let expected = ids(manager.folders)

        // Act
        await manager.refreshFolders(mailboxes: input)
        let actual = ids(manager.folders)

        // Assert
        #expect(actual == expected)
    }

    // MARK: Unread counts

    //Expect: Add up the unread counts of every folder beneath it.
    //Case: When a placeholder parent holds mailboxes at two levels.
    @Test func aggregatedUnreadCount_sumsSubfolders_whenParentIsPlaceholder() {
        // Arrange
        let input: [Mailbox] = [
            Mailbox("Work/Q1", unreadEmails: 5),
            Mailbox("Work/Q1/Jan", unreadEmails: 3),
            Mailbox("Work/Q2", unreadEmails: 2)
        ]
        let expected = 10

        // Act
        let actual = FolderManager.tree(from: input)[0].aggregatedUnreadCount()

        // Assert
        #expect(actual == expected)
    }
}

/// Make one mailbox for each name, all with the same separator.
private func mailboxes(_ names: String..., separator: Character? = nil) -> [Mailbox] {
    names.map { Mailbox($0, pathSeparator: separator) }
}

/// One line per folder, depth first: two spaces of indent per level, the folder's name, and `*` for a placeholder.
private func outline(_ folders: [Folder], indent: String = "") -> [String] {
    folders.flatMap { ["\(indent)\($0.name ?? "")\($0.isPlaceholder ? "*" : "")"] + outline($0.subfolders, indent: indent + "  ") }
}

/// Every folder's `id`, depth first.
private func ids(_ folders: [Folder]) -> [String] {
    folders.flatMap { [$0.id] + ids($0.subfolders) }
}

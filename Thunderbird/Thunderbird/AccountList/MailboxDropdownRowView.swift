// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import BoltUI
import SwiftUI

/// The shared set of folder icons that `iconSwitcher(folderName:tinted:)` draws from.
private let iconShapes = FolderIconShapes()

/// A row in the drawer for one folder, with its icon, name, and unread count.
///
/// A folder with subfolders is a collapsible group that lists its subfolders as nested rows; one without is a plain
/// row. The unread count is the folder's `aggregatedUnreadCount()`, which includes its subfolders. A group shows it only
/// while collapsed and when that total is above zero; a plain row shows it when the folder has unread messages.
///
/// - Important: Tapping a leaf row does nothing yet; loading the folder's email list is a `TODO`. The icon is chosen
///   from the folder's name by `FolderKind.init(folderName:)`. A folder with a `nil` `name` shows an empty name and the generic
///   icon, and a `nil` `unreadEmails` counts as zero.
struct MailboxDropdownRowView: View {
    @State private var isExpanded: Bool = false

    /// The folder to show.
    var folder: Folder

    /// Whether to draw the folder's icon in the accent color. Nothing sets it; it's a placeholder for new-mail state.
    var tempHasNew: Bool = false

    var body: some View {
        if folder.subfolders.count > 0 {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(folder.subfolders) { subfolder in
                    MailboxDropdownRowView(folder: subfolder)
                }
            } label: {
                HStack {
                    (iconSwitcher(folderName: folder.name ?? "", tinted: tempHasNew)).frame(width: 24, height: 24)
                    Text(folder.name ?? "")
                        .foregroundStyle(.black)
                    Spacer()
                    if (!isExpanded && folder.aggregatedUnreadCount() > 0) {
                        UnreadCounter(unreadCount: folder.aggregatedUnreadCount(), hasNew: false)
                    }
                }
            }.font(.subheadline)
                .padding(.leading)
        } else {
            HStack {
                (iconSwitcher(folderName: folder.name ?? "", tinted: tempHasNew)).frame(width: 24, height: 24)
                Text(folder.name ?? "")
                    .foregroundStyle(.black)
                Spacer()
                if (folder.unreadEmails ?? 0) > 0 {
                    UnreadCounter(unreadCount: folder.aggregatedUnreadCount(), hasNew: false)
                }
            }
            .onTapGesture {
                //TODO: Load relevant email list
            }
            .padding(.leading)
            .font(.subheadline)
        }

    }
}

#Preview {
    @Previewable var parentFolder: Folder = Folder(
        name: "name",
        path: "name",
        unreadEmails: 2,
        totalEmails: 10,
        id: "id1",
        mailbox: Mailbox("name"),
        subfolders: [
            Folder(
                name: "place",
                path: "name/place",
                unreadEmails: 2,
                totalEmails: 10,
                id: "id2",
                mailbox: Mailbox("place"),
                subfolders: [
                    Folder(
                        name: "inbox2",
                        path: "name/inbox2",
                        unreadEmails: 2,
                        totalEmails: 10,
                        id: "id4",
                        mailbox: Mailbox("inbox2")
                    )
                ]
            ),
            Folder(
                name: "inbox1",
                path: "name/inbox1",
                unreadEmails: 2,
                totalEmails: 10,
                id: "id3",
                mailbox: Mailbox("inbox1"),
            )
        ]
    )
    MailboxDropdownRowView(folder: parentFolder)
}

/// Return the icon to show beside a folder, chosen by the folder's name.
///
/// - Parameters:
///   - folderName: The folder's display name; see `FolderKind.init(folderName:)` for how it maps to an icon.
///   - tinted: Whether to draw the icon in the accent color instead of black.
/// - Returns: The matching icon, or the generic folder icon if the name matches no special folder.
@ViewBuilder func iconSwitcher(folderName: String, tinted: Bool) -> some View {
    switch FolderKind(folderName: folderName) {
    case .inbox:
        tinted ? iconShapes.inboxPathTinted : iconShapes.inboxPath
    case .archive:
        tinted ? iconShapes.archivePathTinted : iconShapes.archivePath
    case .draft:
        tinted ? iconShapes.draftPathTinted : iconShapes.draftPath
    case .sent:
        tinted ? iconShapes.sentPathTinted : iconShapes.sentPath
    case .spam:
        tinted ? iconShapes.spamPathTinted : iconShapes.spamPath
    case .trash:
        tinted ? iconShapes.trashPathTinted : iconShapes.trashPath
    case .folder:
        tinted ? iconShapes.folderPathTinted : iconShapes.folderPath
    }
}

/// The kind of icon a folder gets in the drawer: one of the special folders, or a generic `folder`.
enum FolderKind: String, CaseIterable {
    case inbox, archive, draft, sent, spam, trash, folder

    /// Choose a folder's kind from its display name.
    ///
    /// A name matches a kind when it contains the kind's English name (for example, "Sent Items" contains "sent"),
    /// ignoring case and diacritics. Kinds are checked in declaration order, so a name that contains two (such as
    /// "Draft Archive") gets the earlier one. A name that matches none is a `folder`.
    ///
    /// - Parameter folderName: The folder's display name.
    /// - Important: Only the English names match; localized folder names aren't recognized yet.
    init(folderName: String) {
        self =
            Self.allCases.first { kind in
                kind != .folder && folderName.localizedCaseInsensitiveContains(kind.rawValue)
            } ?? .folder
    }

    /// The Bolt icon for the kind.
    var icon: Icon {
        switch self {
        case .inbox: .inbox
        case .archive: .archive
        case .draft: .fileDraft
        case .sent: .send
        case .spam: .spam
        case .trash: .trash
        case .folder: .folder
        }
    }
}

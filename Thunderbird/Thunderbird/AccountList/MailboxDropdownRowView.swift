// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI

/// The shared set of folder icons that `iconSwitcher(folderName:tinted:)` draws from.
private let iconShapes = FolderIconShapes()

/// A row in the drawer for one folder, with its icon, name, and unread count.
///
/// A folder with subfolders is a collapsible group that lists its subfolders as nested rows; one without is a plain
/// row. The unread count shows only when the folder has unread messages and, for a group, only while it is collapsed.
/// The count is the folder's `aggregatedUnreadCount()`, which includes its subfolders.
///
/// - Important: Tapping a leaf row does nothing yet; loading the folder's email list is a `TODO`. The icon is chosen
///   from the folder's name by `iconName(folderName:)`. A folder with a `nil` `name` shows an empty name and the generic
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
                    if (!isExpanded && (folder.unreadEmails ?? 0) > 0) {
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
///   - folderName: The folder's display name; see `iconName(folderName:)` for how it maps to an icon.
///   - tinted: Whether to draw the icon in the accent color instead of black.
/// - Returns: The matching icon, or the generic folder icon if the name matches no special folder.
@ViewBuilder func iconSwitcher(folderName: String, tinted: Bool) -> some View {
    switch iconName(folderName: folderName) {
    case "inbox":
        tinted ? iconShapes.inboxPathTinted : iconShapes.inboxPath
    case "archive":
        tinted ? iconShapes.archivePathTinted : iconShapes.archivePath
    case "draft":
        tinted ? iconShapes.draftPathTinted : iconShapes.draftPath
    case "sent":
        tinted ? iconShapes.sentPathTinted : iconShapes.sentPath
    case "spam":
        tinted ? iconShapes.spamPathTinted : iconShapes.spamPath
    case "trash":
        tinted ? iconShapes.trashPathTinted : iconShapes.trashPath
    default:
        tinted ? iconShapes.folderPathTinted : iconShapes.folderPath
    }
}

/// Map a folder's display name to the kind of icon it should have.
///
/// A name matches a kind when it contains the kind's English name (for example, "Sent Items" contains "sent") or its
/// `<kind>_localized` string, ignoring case and diacritics.
///
/// - Parameter folderName: The folder's display name.
/// - Returns: One of `"inbox"`, `"archive"`, `"draft"`, `"sent"`, `"spam"`, or `"trash"`; `"folder"` if none match.
/// - Important: The `<kind>_localized` values are literal strings such as `"inbox_localized"`, not looked up in a
///   string catalog, so only the English names match in practice. The kinds are checked in dictionary order, which is
///   unspecified, so a name that contains two (such as "Draft Archive") may get either icon.
func iconName(folderName: String) -> String {
    let localizedFolderIconNames: [String: String] = [
        "inbox": "inbox_localized",
        "archive": "archive_localized",
        "draft": "draft_localized",
        "sent": "sent_localized",
        "spam": "spam_localized",
        "trash": "trash_localized"
    ]
    for (icon, localizedName) in localizedFolderIconNames {
        if (folderName
            .localizedCaseInsensitiveContains(icon)
            || folderName
                .localizedCaseInsensitiveContains(localizedName))
        {
            return icon
        }
    }
    return "folder"
}

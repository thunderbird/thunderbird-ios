// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI

private let iconShapes = FolderIconShapes()

struct MailboxDropdownRowView: View {
    @State private var isExpanded: Bool = false
    var folder: Folder
    var tempHasNew: Bool = false

    var body: some View {
        if folder.subfolders.count > 0 {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(folder.subfolders) { subfolder in
                    MailboxDropdownRowView(folder: subfolder)
                }
            } label: {
                HStack {
                    (iconSwitcher(folderName: folder.name!, tinted: tempHasNew)).frame(width: 24, height: 24)
                    Text(folder.name!)
                        .foregroundStyle(.black)
                    Spacer()
                    if (!isExpanded && folder.unreadEmails! > 0) {
                        UnreadCounter(unreadCount: folder.unreadEmails!, hasNew: false)
                    }
                }
            }.font(.subheadline)
                .padding(.leading)
        } else {
            HStack {
                (iconSwitcher(folderName: folder.name!, tinted: tempHasNew)).frame(width: 24, height: 24)
                Text(folder.name!)
                    .foregroundStyle(.black)
                Spacer()
                if folder.unreadEmails! > 0 {
                    UnreadCounter(unreadCount: folder.unreadEmails!, hasNew: false)
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

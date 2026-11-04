// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI

/// A collapsible card in the drawer that shows one account and its folders.
///
/// The label shows the account's avatar, name, and (when the name isn't itself an email address) its first identity's
/// address. Expanding the card lists the account's folders as `MailboxDropdownRowView`s. While collapsed, the label
/// shows the total unread count for the account.
///
/// The account comes from the `FolderManager` in the environment, so callers must inject one for the account to show.
///
/// - Important: The collapsed unread count is computed once, when the view first appears, by adding up `unreadEmails`
///   for the account's top-level folders. It doesn't include subfolders or refresh afterward. A folder with a `nil`
///   `unreadEmails` counts as zero.
struct AccountFolderDisclosureView: View {
    @Environment(FolderManager.self) private var folderManager: FolderManager
    @State private var isExpanded: Bool = false
    @State private var unreadCount: Int = 0

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(folderManager.folders) { folder in
                MailboxDropdownRowView(folder: folder)
            }
            .padding(.vertical, 10)
        } label: {
            HStack {
                AvatarView(
                    displayName: folderManager.account.name,
                    bubbleColor: Color(folderManager.account.avatarColor)
                )
                VStack(alignment: .leading) {
                    Text(folderManager.account.name)
                        .font(.body)
                        .truncationMode(.middle)
                    if (!folderManager.account.name.isEmailAddress) {
                        Text(folderManager.account.identities[0].email)
                            .font(.caption2)
                            .truncationMode(.middle)
                    }
                }.padding(.horizontal)
                    .foregroundStyle(.black)
                Spacer()
                if (!isExpanded && unreadCount > 0) {
                    UnreadCounter(unreadCount: unreadCount, hasNew: false)
                }
            }.padding(.vertical, 10)
                .safeAreaPadding(.horizontal)
        }.task {
            for folder in folderManager.folders {
                unreadCount += folder.unreadEmails ?? 0
            }
        }.padding(.horizontal, 10)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .foregroundStyle(.white)
            }
    }
}

#Preview {
    @Previewable @State var mailboxes: FolderManager = FolderManager(account: Account("temp@email.com"))

    AccountFolderDisclosureView()
        .environment(mailboxes)
}

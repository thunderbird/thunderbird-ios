// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI

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
                unreadCount += folder.unreadEmails!
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

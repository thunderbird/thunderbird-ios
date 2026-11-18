// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import BoltUI
import SwiftUI

/// One folder row in the `AccountDrawerView`.
///
/// - Parameters:
///   - id: Stable identity for the row; also what `AccountDrawerView` compares against its `selection`.
///   - name: The folder's display name. `FolderKind(folderName:)` picks the row's icon from it.
///   - unreadCount: Unread messages in the folder; the badge is hidden when it is zero.
///   - depth: How many levels the folder is nested below the account's top-level folders.
///   - isExpandable: Whether the folder has subfolders, which adds a disclosure chevron to the row.
///   - isExpanded: Whether an expandable folder's subfolders are showing; sets the chevron's direction.
struct DrawerFolder: Identifiable {
    let id: String
    let name: String
    var unreadCount: Int = 0
    var depth: Int = 0
    var isExpandable: Bool = false
    var isExpanded: Bool = false
}

/// The account drawer redesigned on Bolt: an account card listing the account's folders, over a bottom Settings button.
///
/// The account's display name leads, with its email address beneath it. The selected folder gets a soft highlight. Icons
/// are Bolt `Icon`s, and colors, type sizes and shadows are Bolt tokens. The view draws the drawer only; it doesn't
/// slide in, dim what's behind it, or read the `AccountManager`, so `DrawerView` still presents the live drawer.
///
/// - Parameters:
///   - displayName: The account's display name, shown first and used for the avatar's initials.
///   - email: The account's email address, shown under the display name.
///   - avatarColor: The color of the avatar's initials, outline, and tint.
///   - folders: The folders to list, top to bottom, with subfolders already flattened in and `depth` set.
///   - selection: The `id` of the selected folder.
///   - onSettings: Called when Settings is tapped.
struct AccountDrawerView: View {
    var displayName: String
    var email: String
    var avatarColor: Color = Color(.primary(.default))
    var folders: [DrawerFolder]
    var selection: String?
    var onSettings: () -> Void = {}

    @State private var isExpanded: Bool = true

    // MARK: View
    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            VStack(spacing: 0.0) {
                accountHeader
                if isExpanded {
                    VStack(spacing: 0.0) {
                        ForEach(folders) { folder in
                            FolderRow(folder: folder, isSelected: folder.id == selection)
                        }
                    }
                    .padding(.top, density: .compact)
                }
            }
            .padding(4.0)
            .background(Color(.surface(.raised)), in: RoundedRectangle(cornerRadius: .cornerRadius))
            .padding(.horizontal, density: .default)
            .padding(.top, density: .default)

            Spacer(minLength: 0.0)

            Button(action: onSettings) {
                Text("settings_header")
                    .font(.system(size: 17.0, weight: .medium))
                    .foregroundStyle(Color(.textIcon(.secondary)))
                    .padding(.horizontal, density: .relaxed)
                    .frame(height: 48.0)
                    .background(Color(.surface(.raised)), in: Capsule())
                    .shadow(.level2)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, density: .default)
            .padding(.vertical, 4.0)
        }
        .frame(maxWidth: 386.0, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.surface(.lower)))
    }

    private var accountHeader: some View {
        Button {
            isExpanded.toggle()
        } label: {
            HStack(spacing: .padding(.compact)) {
                AvatarView(displayName: displayName, bubbleColor: avatarColor)
                    .frame(width: 40.0, height: 40.0)
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(displayName)
                        .textStyle(.bodyLarge)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(email)
                        .textStyle(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .foregroundStyle(Color(.textIcon(.base)))
                Spacer(minLength: 0.0)
                Image(isExpanded ? Icon.chevronUp : Icon.chevronDown)
                    .font(.system(size: 20.0))
                    .foregroundStyle(Color(.textIcon(.base)))
                    .frame(width: 44.0, height: 44.0)
            }
            .padding(.leading, 4.0)
            .frame(height: 48.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(displayName), \(email)"))
        .accessibilityValue(Text(isExpanded ? "expanded" : "collapsed"))
    }
}

/// A 48pt folder row: Bolt icon, name, unread badge, and a chevron when the folder has subfolders.
private struct FolderRow: View {
    var folder: DrawerFolder
    var isSelected: Bool

    // MARK: View
    var body: some View {
        HStack(spacing: .padding(.compact)) {
            Image(FolderKind(folderName: folder.name).icon)
                .font(.system(size: 24.0))
                .foregroundStyle(Color(.textIcon(.base)))
                .frame(width: 48.0, height: 48.0)
            Text(folder.name)
                .textStyle(.body)
                .foregroundStyle(Color(.textIcon(.base)))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 0.0)
            HStack(spacing: 0.0) {
                if folder.unreadCount > 0 {
                    UnreadBadge(count: folder.unreadCount)
                }
                // Every row keeps the chevron's 44pt slot, so badges line up whether or not the folder expands.
                ZStack {
                    if folder.isExpandable {
                        Image(folder.isExpanded ? Icon.chevronUp : Icon.chevronDown)
                            .font(.system(size: 20.0))
                            .foregroundStyle(Color(.textIcon(.base)))
                    }
                }
                .frame(width: 44.0, height: 44.0)
            }
        }
        .padding(.leading, CGFloat(folder.depth) * .padding())
        .frame(height: 48.0)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: .cornerRadius)
                    .fill(Color(.primary(.soft)))
                    .overlay {
                        RoundedRectangle(cornerRadius: .cornerRadius)
                            .strokeBorder(Color(.primary(.default)).opacity(0.15), lineWidth: 1.0)
                    }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// The unread-count pill: Bolt primary fill, white bold 11pt count, at least 20pt wide and 17pt tall.
private struct UnreadBadge: View {
    var count: Int

    // MARK: View
    var body: some View {
        Text("\(count)")
            .font(.system(size: 11.0, weight: .bold))
            .foregroundStyle(Color(.surface(.raised)))
            .padding(.horizontal, 6.0)
            .frame(minWidth: 20.0, minHeight: 17.0)
            .background(Color(.primary(.default)), in: Capsule())
    }
}

private let previewFolders: [DrawerFolder] = [
    DrawerFolder(id: "inbox", name: "Inbox", unreadCount: 2),
    DrawerFolder(id: "drafts", name: "Drafts", unreadCount: 2),
    DrawerFolder(id: "sent", name: "Sent"),
    DrawerFolder(id: "archive", name: "Archive"),
    DrawerFolder(id: "trash", name: "Trash"),
    DrawerFolder(id: "spam", name: "Spam"),
    DrawerFolder(id: "example", name: "Example folder", isExpandable: true, isExpanded: true),
    DrawerFolder(id: "sub1", name: "Example sub-folder", depth: 1, isExpandable: true, isExpanded: true),
    DrawerFolder(id: "sub2", name: "Example sub-folder", unreadCount: 12, depth: 2)
]

#Preview("Account Drawer - Inbox active") {
    AccountDrawerView(
        displayName: "Roc Thunderbird",
        email: "roc@thunderbird.net",
        folders: previewFolders,
        selection: "inbox"
    )
}

#Preview("Account Drawer - Dark") {
    AccountDrawerView(
        displayName: "Roc Thunderbird",
        email: "roc@thunderbird.net",
        folders: previewFolders,
        selection: "inbox"
    )
    .preferredColorScheme(.dark)
}

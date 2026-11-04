// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Bolt
import Core
import SwiftUI

/// List of saved accounts, with swipe actions to edit or delete each one and a toolbar button to add another.
///
/// Not currently shown in the app; it's only referenced by its preview.
struct AccountListView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @State private var account: Account? = nil
    @State private var isPresented: Bool = false

    // MARK: View
    var body: some View {
        List {
            ForEach(accountManager.allAccounts, id: \.self) { account in
                NavigationLink(destination: {
                    ContentUnavailableView(account.name, systemImage: "mail")
                }) {
                    Text(account.name)
                }
                .swipeActions {
                    Button(
                        role: .destructive,
                        action: { accountManager.delete(account) }
                    ) {
                        Label("delete_button", systemImage: "trash")
                    }
                    Button(action: {
                        self.account = account
                        isPresented = true
                    }) {
                        Label("edit_account_header", systemImage: "gearshape")
                            .labelStyle(.iconOnly)
                    }
                }
            }
        }
        .navigationTitle("accounts_heading")
        .toolbar {
            Button(action: {
                account = nil
                isPresented = true
            }) {
                Label("add_account_header", systemImage: "plus")
            }
        }
        .sheet(isPresented: $isPresented, onDismiss: { account = nil }) {
            NavigationStack {
                AccountView(account, isPresented: $isPresented)
            }
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview("Account List View") {
    @Previewable @State var accountManager: AccountManager = AccountManager()

    NavigationStack {
        AccountListView()
    }
    .environment(accountManager)
}

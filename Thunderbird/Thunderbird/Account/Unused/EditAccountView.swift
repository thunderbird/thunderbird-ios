// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/s

import Account
import SwiftUI

/// Older account editor with separate incoming and outgoing server sections.
///
/// Not currently shown in the app; it's only referenced by its preview. The setup flow uses ``AccountEditView``.
// TODO: Delete this view, or wire it back into the app. It is dead code while the setup flow uses `AccountEditView`.
struct EditAccountView: View {
    /// - Parameter account: Account to edit. Its incoming and outgoing servers are copied, so changes apply only when saved.
    init(_ account: Account) {
        self.account = account
        self.incomingServer = account.incomingServer?.clone() ?? Server(.imap)
        self.outgoingServer = account.outgoingServer?.clone() ?? Server(.smtp)
    }

    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(\.dismiss) private var dismiss: DismissAction
    @State private var account: Account
    @State private var incomingServer: Server
    @State private var outgoingServer: Server

    // MARK: View
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Incoming Server")
                    .font(.headline)
                EditServerView($incomingServer, $account)
                Divider()
                Text("Outgoing Server")
                    .font(.headline)
                EditServerView($outgoingServer, $account)

            }
            .padding()
        }
        .navigationTitle("Edit Account")
        .toolbar {
            Button(action: {
                account.servers = [
                    incomingServer,
                    outgoingServer
                ]
                accountManager.set(account)
                dismiss()
            }) {
                Text("Save")
            }
        }
    }
}

#Preview("Edit Account View") {
    NavigationStack {
        EditAccountView(Account("example@thunderbird.net"))
    }
}

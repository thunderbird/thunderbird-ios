//
//  AccountDrawerView.swift
//  Thunderbird
//

import Account
import SwiftUI

struct AccountDrawerView: View {
    @Environment(Accounts.self) private var accounts: Accounts

    // MARK: View
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 17.0) {
                    ForEach(accounts.allAccounts) { account in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(account.name)
                                    .font(.headline)
                                if let email = account.identities.first?.emailAddress {
                                    Text(String(describing: email))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .addAccount) {
                    NavigationLink(destination: {
                        AddAccountView()
                    }) {
                        Label("Add Account", systemImage: "plus")
                    }
                }
            }
        }
    }
}

#Preview("Account Drawer") {
    @Previewable @State var accounts: Accounts = Accounts()
    AccountDrawerView().environment(accounts)
}

private extension ToolbarItemPlacement {
    static var addAccount: Self {
        #if os(iOS)
        .bottomBar
        #else
        .automatic
        #endif
    }
}

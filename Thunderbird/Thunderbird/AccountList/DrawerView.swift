// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI

struct DrawerView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Binding var showDrawer: Bool

    // MARK: View
    var body: some View {

        ZStack {
            if showDrawer {
                Button {
                    showDrawer.toggle()
                } label: {
                    Rectangle()
                        .fill(Color.primary.opacity(0.3))
                        .ignoresSafeArea()
                }
                .accessibilityLabel("dismiss")

                HStack {
                    VStack(alignment: .leading) {
                        ScrollView {
                            DrawerContent(showDrawer: $showDrawer)
                        }.toolbar {
                            ToolbarItem(id: "settings", placement: .bottom) {
                                NavigationLink(destination: GeneralSettingsView()) {
                                    Text("settings_header")
                                        .foregroundStyle(.black)
                                }
                            }
                            ToolbarItem(placement: .bottom) {
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(.surface)
                    Spacer()
                }
                .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut, value: showDrawer)
        .toolbar(showDrawer ? .hidden : .visible, for: .navigation)
    }
}

#Preview("Account Drawer") {
    @Previewable @State var accountManager: AccountManager = AccountManager()
    @Previewable @State var showDrawer: Bool = true

    DrawerView(showDrawer: $showDrawer)
        .environment(accountManager)
}

struct DrawerContent: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Binding var showDrawer: Bool

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(accountManager.allAccounts) { account in
                let mailboxes: FolderManager = FolderManager(account: account)
                AccountFolderDisclosureView()
                    .environment(mailboxes)
            }
        }
    }
}

private extension ToolbarPlacement {
    static var navigation: Self {
        #if os(iOS)
        .navigationBar
        #else
        .automatic
        #endif
    }
}

private extension ToolbarItemPlacement {
    static var bottom: Self {
        #if os(iOS)
        .bottomBar
        #else
        .automatic
        #endif
    }
}

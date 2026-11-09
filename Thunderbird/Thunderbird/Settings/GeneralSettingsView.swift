// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI

/// The app's settings screen: the signed-in accounts, a way to add one, and a few miscellaneous links.
///
/// Reached from the drawer's Settings link (`DrawerView`). It lists every account in `AccountManager.allAccounts`, each
/// with a menu to sign it out, and links to ``ManualAccount`` to add another, to ``FeatureFlagDebugView``, and to the
/// donation page in the browser.
///
/// - Important: The "Sign out" menu item calls `AccountManager.delete(_:)`, which removes the account and its stored
///   authorization from the device. Nothing asks for confirmation first.
/// - Important: "Add Account" opens the manual setup form, not the autoconfiguration sign-in flow.
/// - Note: The "General Settings" section is empty. The "General Settings", "Miscellaneous", "Add Account" and
///   "Feature Flags" titles have no entry in `Localizable.strings`, so they show in English in every language.
///   `.navigationTitle("settings_header")` is applied to the `NavigationStack` itself rather than to the list inside
///   it, so it probably doesn't set the title (verify).
struct GeneralSettingsView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(\.openURL) private var openURL: OpenURLAction

    var body: some View {
        NavigationStack {
            List {
                Section("General Settings") {

                }
                Section("accounts_heading") {
                    ForEach(accountManager.allAccounts) { account in
                        HStack {
                            Text(account.name)
                            Spacer()
                            Menu {
                                Button(action: {
                                    accountManager.delete(account)
                                }) {
                                    Text("account_sign_out_button")
                                }
                            } label: {
                                Label("options_button", systemImage: "ellipsis")
                                    .labelStyle(.iconOnly)
                                    .foregroundStyle(.black)
                            }.compositingGroup()

                        }
                    }
                    NavigationLink(destination: {
                        ManualAccount()
                    }) {
                        Label("Add Account", systemImage: "plus")
                    }.navigationLinkIndicatorVisibility(.hidden)
                }
                Section("Miscellaneous") {
                    NavigationLink("Feature Flags", destination: FeatureFlagDebugView())
                    Button(
                        "donation_support",
                        action: {
                            guard let url = URL(string: "https://www.thunderbird.net/en-US/donate/") else { return }
                            openURL(url)
                        })
                }
            }
        }.navigationTitle("settings_header")
    }
}

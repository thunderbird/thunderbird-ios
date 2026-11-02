// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Autoconfiguration
import SwiftUI

/// First screen of the manual setup flow: enter an email address, look up its settings, and sign in.
///
/// From here, the user can edit the configuration found in ``ManualServerSetup``, or choose a protocol and enter servers by hand starting with ``EmailAccountTypeSelection``. A temporary **Demo** button autoconfigures and saves `demoEmail@gmail.com`.
struct AccountInformation: View {
    /// - Parameter path: Navigation path to push the next screen onto.
    init(_ path: Binding<NavigationPath>) {
        _path = path
    }

    /// Navigation path for the manual setup flow.
    @Binding var path: NavigationPath
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(LoginDetails.self) private var loginDetails: LoginDetails
    @State private var account: Account = Account()
    /// Whether to show the manual configuration link. Always `true`; nothing changes it.
    @State private var showManual: Bool = true
    @State private var emailAddress: String = ""
    @State private var password: String = ""
    @State private var error: Error?
    @State private var loginServer: Server = Server(.imap)
    @State private var loginAuth: Authorization = .none

    /// Look up settings for the entered address, showing any error on the account manager.
    private func autoconfigure() async {
        accountManager.error = nil
        do {
            account = try await account.autoconfigured()
        } catch {
            accountManager.error = AccountError(error) ?? .autoconfig(error)
        }
    }

    var body: some View {
        Form {
            TextEntryWrapper("account_server_settings_email_value_label", "your.email@example.com", $emailAddress)
                #if os(iOS)
            .keyboardType(.emailAddress)
            .submitLabel(.search)
                #endif
                .onChange(of: emailAddress) {
                    account.identities = [
                        EmailAddress(emailAddress)
                    ]
                    account.autoconfigured = nil
                }
            Button(action: {
                Task { await autoconfigure() }
            }) {
                HStack {
                    Spacer()
                    Label("Search Configurations", systemImage: "magnifyingglass")
                    Spacer()
                }
                .padding(5.5)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accent)
            .disabled(!emailAddress.isEmailAddress)
            .listRowSeparator(.hidden)
            if let source: Source = account.autoconfigured {
                VStack(alignment: .leading) {
                    HStack {
                        Label("Configuration found!", systemImage: "gearshape")
                            .font(.headline)
                        Spacer()
                    }
                    HStack {
                        Text("Source:")
                            .bold()
                        Text(source.description)
                        Spacer()
                    }
                    .padding(.vertical)
                    AuthorizationView($account, error: $error)
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 22.0)
                        .fill(.gray.opacity(0.17))
                }
                .listRowSeparator(.hidden)
                Button(action: {
                    loginDetails.inProgressAccount = account
                    loginDetails.enteredEmail = emailAddress
                    path.append("ManualAccountSetup")
                }) {
                    Text("account_server_edit_configuration")
                        .padding(.horizontal)
                        .underline()
                }
                .listRowSeparator(.hidden)
            }
            Spacer(minLength: 64.0)
            // TYPE SELECTION FLOW
            if error != nil || showManual {
                Button(
                    action: {
                        loginDetails.inProgressAccount = nil
                        path.append("EmailAccountTypeSelection")

                    }) {
                        Text("account_server_manual_configuration")
                            .padding(5.5)
                            .frame(maxWidth: .infinity)
                            .underline()

                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .buttonStyle(.plain)
            }
            // TEMP DEMO BUTTON
            Button(action: {
                Task {
                    guard let account: Account = try? await .autoconfigured("demoEmail@gmail.com") else {
                        return
                    }
                    accountManager.set(account)
                }
            }) {
                Text("Demo")
                    .padding(5.5)
                    .frame(maxWidth: .infinity)
                    .underline()

            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("account_server_information_title")
        .scrollContentBackground(.hidden)
    }
}

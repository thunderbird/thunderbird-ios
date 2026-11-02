// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Bolt
import Core
import SwiftUI

/// Review the settings autoconfiguration found, choose between them, sign in, then test or save the account.
///
/// When the provider also supports JMAP, both configurations are offered and only one can be selected; the autoconfigured one is selected by default. Pull to refresh repeats both lookups.
struct AccountAutoView: View {
    /// - Parameters:
    ///   - account: Autoconfigured account. The lookup is repeated when the view appears, and the result replaces it.
    ///   - path: Navigation path, used to open ``AccountEditView`` for either configuration.
    ///   - isPresented: Binding to the presenting sheet; set to `false` when the account is saved.
    init(
        _ account: Binding<Account>,
        path: Binding<NavigationPath> = .constant(NavigationPath()),
        isPresented: Binding<Bool> = .constant(false)
    ) {
        _isPresented = isPresented
        _account = account
        _path = path
    }

    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Binding private var isPresented: Bool
    @Binding private var account: Account
    @Binding private var path: NavigationPath
    @State private var jmapAccount: Account? = nil
    @State private var isRefreshing: Bool = false
    @State private var isJMAPSelected: Bool = false
    @State private var isAutoSelected: Bool = true
    @State private var isTesting: Bool = false
    /// Last sign-in error. Setting it also shows it on the account manager, but only errors ``AccountError`` can represent are shown; others are dropped.
    @State private var error: Error? = nil {
        didSet { accountManager.error = error != nil ? AccountError(error!) : nil }
    }

    /// The JMAP configuration when it's available and selected, otherwise the autoconfigured account.
    private var selectedAccount: Account {
        if isJMAPSelected, let jmapAccount {
            return jmapAccount
        }
        return account
    }

    /// Repeat the JMAP lookup and autoconfiguration. JMAP lookup errors are ignored; autoconfiguration errors are shown on the account manager.
    private func refresh() async {
        accountManager.error = nil
        isRefreshing = true
        do {
            jmapAccount = try? await account.jmapConfigured()
            account = try await account.autoconfigured()
        } catch {
            accountManager.error = AccountError(error) ?? .autoconfig(error)
        }
        isRefreshing = false
    }

    /// Save the selected configuration and dismiss the sheet.
    private func save() {
        accountManager.set(selectedAccount)
        isPresented = false
    }

    /// Show ``AccountTestView`` for the selected configuration.
    private func test() {
        isTesting = true
    }

    // MARK: View
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacing()) {
                Text(account.emailAddress?.description ?? "")
                    .bold()
                if let jmapAccount {
                    Toggle(isOn: $isJMAPSelected) {
                        ConfigurationView(jmapAccount) {
                            self.account = jmapAccount
                            path.append(AccountDestination.edit)
                        }
                    }
                    .fullToggleStyle()
                    .onChange(of: isJMAPSelected) {
                        isAutoSelected = !isJMAPSelected
                    }
                }
                Toggle(isOn: $isAutoSelected) {
                    ConfigurationView(account) {
                        path.append(AccountDestination.edit)
                    }
                }
                .fullToggleStyle()
                .onChange(of: isAutoSelected) {
                    isJMAPSelected = !isAutoSelected
                }
                AuthorizationView($account, error: $error)
                    .padding(.vertical, density: .compact)
                    .onChange(of: account.authenticationType) {
                        jmapAccount?.authenticationType = account.authenticationType
                    }
                Divider()
                HStack {
                    Spacer()
                    AccountTestButton { test() }
                        .buttonStyle(.bordered)
                    AccountSaveButton { save() }
                        .buttonStyle(.borderedProminent)
                        .labelStyle(.titleOnly)
                }
            }
            .padding(density: .default)
        }
        .navigationTitle("auto_account_header")
        .toolbar {
            AccountTestButton { test() }
            AccountSaveButton { save() }
                .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $isTesting) {
            AccountTestView(selectedAccount)
                .presentationDragIndicator(.visible)
        }
        .refreshable(action: {
            await refresh()
        })
        .task {
            await refresh()
        }
    }
}

#Preview("Account Auto View") {
    @Previewable @State var accountManager: AccountManager = AccountManager()
    @Previewable @State var account: Account = Account("Pat Example <example@fastmail.com>")
    @Previewable @State var path: NavigationPath = NavigationPath()

    NavigationStack(path: $path) {
        AccountAutoView($account, path: $path)
            .environment(accountManager)
    }
}

/// Summary of an account's protocol, servers and connection security, with a link to edit it.
struct ConfigurationView: View {
    /// Account whose configuration is shown.
    let account: Account

    /// - Parameters:
    ///   - account: Account to summarize.
    ///   - action: Called when the edit link is tapped.
    init(_ account: Account, action: @escaping @MainActor () -> Void = {}) {
        self.account = account
        self.action = action
    }

    private let action: () -> Void

    // MARK: View
    var body: some View {
        VStack(alignment: .leading) {
            Text(account.emailProtocol.titleKey)
                .font(.headline)
            ForEach(account.servers) { server in
                Text("\(server.hostname):\(server.port)")
                    .font(.subheadline)
                    .monospaced()
            }
            Text(account.servers.first?.connectionSecurity.description ?? "")
                .font(.subheadline)
            Button(action: action) {
                Text("account_server_edit_configuration")
                    .font(.caption)
            }
            .padding(.top, density: .compact)
        }
    }
}

#Preview("Configuration View") {
    @Previewable @State var account: Account = Account("example@thunderbird.net")

    ConfigurationView(account)
        .padding()
}

/// Extends `Account.EmailProtocol` with localized titles for display.
private extension Account.EmailProtocol {
    /// Localization key for the protocol's name.
    var titleKey: LocalizedStringKey {
        switch self {
        case .imap: "imap"
        case .jmap: "jmap"
        }
    }
}

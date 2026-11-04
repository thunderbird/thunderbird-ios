// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Bolt
import Core
import SwiftUI

/// First step of adding an account: enter an email address and display name, then look up its settings.
///
/// **Next** runs autoconfiguration and continues to ``AccountAutoView``. The manual configuration link skips straight to ``AccountEditView``.
struct AccountAddView: View {
    /// - Parameters:
    ///   - account: Account being set up. Its identity is replaced as the fields change, and the whole account is replaced by the autoconfigured one when the lookup succeeds.
    ///   - path: Navigation path to push the next screen onto.
    ///   - autofocus: Whether to focus the email address field when the view appears.
    init(
        _ account: Binding<Account>,
        path: Binding<NavigationPath> = .constant(NavigationPath()),
        autofocus: Bool = false
    ) {
        _account = account
        _path = path
        self.autofocus = autofocus
    }

    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Binding private var account: Account
    @Binding private var path: NavigationPath
    @State private var valueText: String = ""
    @State private var labelText: String = ""
    @FocusState private var isValueFocused: Bool
    @FocusState private var isLabelFocused: Bool
    @State private var isSearching: Bool = false
    private let autofocus: Bool

    /// Whether **Next** is disabled: the address isn't valid, or a lookup is already running.
    private var isDisabled: Bool { !valueText.isEmailAddress || isSearching }

    /// Replace the account's identities with the address and label currently entered.
    // TODO: This drops any other identities the account has; update the first identity instead.
    private func refreshEmailAddress() {
        account.identities = [
            EmailAddress(valueText, label: labelText)
        ]
    }

    /// Look up the account's settings and continue to ``AccountAutoView``, or show the error on the account manager.
    private func autoconfigure() async {
        accountManager.error = nil
        isSearching = true
        do {
            account = try await account.autoconfigured()
            path.append(AccountDestination.auto)
        } catch {
            accountManager.error = AccountError(error) ?? .autoconfig(error)
        }
        isSearching = false
    }

    // MARK: View
    var body: some View {
        VStack(spacing: .spacing()) {
            Spacer()
            TextField("your.email@example.com", text: $valueText)
                .formInput("account_server_settings_email_value_label", isRequired: true)
                .autoFormattingDisabled()
                #if os(iOS)
            .keyboardType(.emailAddress)
            .submitLabel(.continue)
                #endif
                .focused($isValueFocused, equals: true)
                .onSubmit {
                    isLabelFocused = true
                }
            TextField("Pat Example", text: $labelText)
                .formInput("account_server_settings_email_label_label")
                .autoFormattingDisabled()
                #if os(iOS)
            .submitLabel(.continue)
                #endif
                .focused($isLabelFocused, equals: true)
                // TODO: Check `isDisabled` here, as the Next button does. Return currently starts a lookup for an invalid address, or a second lookup while one is running.
                .onSubmit {
                    Task { await autoconfigure() }
                }
            HStack {
                Spacer()
                Button(action: {
                    Task { await autoconfigure() }
                }) {
                    Text("next_button")
                        .padding(.horizontal, density: .compact)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isDisabled)
            }
            Spacer()
            Spacer()
            Button(action: {
                path.append(AccountDestination.edit)
            }) {
                Text("account_server_manual_configuration")
            }
        }
        .navigationTitle("add_account_header")
        .onChange(of: valueText) {
            refreshEmailAddress()
        }
        .onChange(of: labelText) {
            refreshEmailAddress()
        }
        .onAppear {
            valueText = account.emailAddress?.value ?? ""
            labelText = account.emailAddress?.label ?? ""
            isValueFocused = autofocus
        }
        .padding(density: .default)
    }
}

#Preview("Account Add View") {
    @Previewable @State var accountManager: AccountManager = AccountManager()
    @Previewable @State var account: Account = Account("Pat Example <example@thunderbird.net>")
    @Previewable @State var path: NavigationPath = NavigationPath()

    NavigationStack(path: $path) {
        AccountAddView($account, path: $path)
            .environment(accountManager)
    }
}

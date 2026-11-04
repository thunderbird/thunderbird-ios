// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Bolt
import Core
import SwiftUI

/// Screens the account setup flow can push onto its navigation stack.
enum AccountDestination: String, CaseIterable, CustomStringConvertible {
    /// `add` enters an email address, `auto` reviews autoconfigured settings, and `edit` sets up servers by hand.
    case add, auto, edit

    // MARK: CustomStringConvertible
    var description: String { rawValue }
}

/// Root of the account setup flow, presented as a sheet to add a new account or edit an existing one.
///
/// New accounts (with no servers yet) start at ``AccountAddView`` and continue to ``AccountAutoView`` or ``AccountEditView``. Accounts that already have servers open directly in ``AccountEditView``.
struct AccountView: View {
    /// Start adding an account for an email address.
    ///
    /// - Parameter emailAddress: Address to prefill in ``AccountAddView``.
    init(_ emailAddress: EmailAddress) {
        self.init(Account(emailAddress))
    }

    /// Add a new account, or edit an existing one.
    ///
    /// - Parameters:
    ///   - account: Account to edit. When `nil`, or when the account has no servers, the flow starts at ``AccountAddView``.
    ///   - isPresented: Binding to the presenting sheet; set to `false` when the account is saved.
    init(_ account: Account? = nil, isPresented: Binding<Bool> = .constant(false)) {
        _isPresented = isPresented
        let account: Account = account ?? Account()
        self.account = account
        destination = account.servers.isEmpty ? .add : .edit
    }

    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Binding private var isPresented: Bool
    @State private var account: Account
    @State private var path: NavigationPath = NavigationPath()
    private let destination: AccountDestination

    // MARK: View
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                switch destination {
                case .edit:
                    AccountEditView($account, isPresented: $isPresented)
                default:
                    AccountAddView($account, path: $path, autofocus: true)
                        .navigationDestination(for: AccountDestination.self) { destination in
                            switch destination {
                            case .auto: AccountAutoView($account, path: $path, isPresented: $isPresented)
                            default: AccountEditView($account, isPresented: $isPresented)
                            }
                        }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseButton("close_button")
                }
            }
        }
    }
}

#Preview("Account View") {
    @Previewable @State var accountManager: AccountManager = AccountManager()

    AccountView("Pat Example <example@thunderbird.net>")
        .environment(accountManager)
}

/// Save button for the account setup screens.
struct AccountSaveButton: View {
    /// - Parameter action: Called when the button is tapped.
    init(action: @escaping () -> Void) {
        self.action = action
    }

    private let action: () -> Void

    // MARK: View
    var body: some View {
        Button(action: action) {
            Label("save_button", systemImage: "checkmark")
        }
    }
}

#Preview("Account Save Button") {
    AccountSaveButton {
        print("Save")
    }
    .padding()
}

/// Button that starts a connection test for the account being set up.
struct AccountTestButton: View {
    /// - Parameter action: Called when the button is tapped.
    init(action: @escaping () -> Void) {
        self.action = action
    }

    private let action: () -> Void

    // MARK: View
    var body: some View {
        Button(action: action) {
            Label("test_button", systemImage: "stethoscope")
        }
    }
}

#Preview("Account Test Button") {
    AccountTestButton {
        print("Test")
    }
    .padding()
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import BoltUI
import SwiftUI

/// Sheet that hosts the manual account setup flow, starting at ``AccountInformation``.
///
/// It dismisses itself as soon as the number of saved accounts changes, which is how a successful save closes it.
struct ManualAccount: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(\.dismiss) private var dismiss: DismissAction
    @State private var loginDetails: LoginDetails = LoginDetails()
    @State private var path: NavigationPath = NavigationPath()

    // MARK: View
    var body: some View {
        NavigationStack(path: $path) {
            AccountInformation($path)
                .environment(loginDetails)
                .environment(accountManager)
                .toolbarRole(.editor)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        CloseButton("close_button")
                    }
                }
                .onChange(of: accountManager.allAccounts.count) {
                    dismiss()
                }
                .navigationBarBackButtonHidden()
                .navigationDestination(for: String.self) { destination in
                    if destination == "EmailAccountTypeSelection" {
                        EmailAccountTypeSelection($path).toolbarRole(.editor).environment(loginDetails)
                    }
                    if destination == "ManualAccountSetup" {
                        if loginDetails.inProgressAccount == nil {
                            ManualServerSetup(loginDetails)
                                .toolbarRole(.editor)
                                .environment(accountManager)
                                .environment(loginDetails)
                        } else {
                            ManualServerSetup(loginDetails)
                                .toolbarRole(.editor)
                                .environment(accountManager)
                                .environment(loginDetails)
                        }
                    }
                }
        }.accentColor(.gray)
    }
}

#Preview("Manual Account Setup") {
    @Previewable @State var accountManager: AccountManager = AccountManager()
    @Previewable @State var getStarted: Bool = false

    ManualAccount()
        .environment(accountManager)
        .sheet(isPresented: $getStarted) {
            EmptyView()
                .presentationDragIndicator(.visible)
        }
}

@Observable
/// State shared between the manual setup screens.
class LoginDetails {
    /// Autoconfigured account the user chose to edit, if any.
    var inProgressAccount: Account?
    /// Email address entered on ``AccountInformation``.
    var enteredEmail: String
    /// Protocol chosen in ``EmailAccountTypeSelection``; `nil` when editing an autoconfigured account.
    var serverProtocol: ServerProtocol?

    /// - Parameters:
    ///   - inProgressAccount: Autoconfigured account being edited, if any.
    ///   - enteredEmail: Email address entered so far.
    ///   - serverProtocol: Protocol chosen for manual setup, if any.
    init(inProgressAccount: Account? = nil, enteredEmail: String = "", serverProtocol: ServerProtocol? = nil) {
        self.inProgressAccount = inProgressAccount
        self.enteredEmail = enteredEmail
        self.serverProtocol = serverProtocol
    }
}

//
//  ManualAccount.swift
//  Thunderbird
//
//  Created by Ashley Soucar on 7/22/25.
//

import SwiftUI
import Account

struct ManualAccount: View {
    @Environment(Accounts.self) private var accounts: Accounts
    @Environment(\.dismiss) private var dismiss
    @State private var loginDetails: LoginDetails = LoginDetails()
    @State private var path = NavigationPath()

    // MARK: View
    var body: some View {
        NavigationStack(path: $path) {
            AccountInformation($path)
                .environment(loginDetails)
                .environment(accounts)
                .toolbarRole(.editor)
                .toolbar {
                    ToolbarItem(id: "navBar", placement: .cancellationAction) {
                        Button(
                            "close_button", systemImage: "xmark",
                            action: {
                                dismiss()
                            })
                    }
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
                                .environment(accounts)
                                .environment(loginDetails)
                        } else {
                            ManualServerSetup(loginDetails)
                                .toolbarRole(.editor)
                                .environment(accounts)
                                .environment(loginDetails)
                        }

                    }
                }
        }.accentColor(.gray)
    }
}

#Preview("Manual Account Setup") {
    @Previewable @State var getStarted: Bool = false
    @Previewable @State var accounts: Accounts = Accounts()

    ManualAccount()
        .environment(accounts)
        .sheet(isPresented: $getStarted) {
            EmptyView()
                .presentationDragIndicator(.visible)
        }
}

private struct Background: View {

    // MARK: View
    var body: some View {
        GeometryReader { proxy in
            Image.background
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .opacity(proxy.size.width > 444.0 ? 0.0 : 1.0)
        }
        .ignoresSafeArea()
    }
}

private extension Image {
    static var background: Self { Self("Welcome/Background") }
    static var logo: Self { Self("Welcome/Logo") }
}

@Observable
class LoginDetails {
    var inProgressAccount: Account?
    var enteredEmail: String
    var serverProtocol: ServerProtocol?

    init(inProgressAccount: Account? = nil, enteredEmail: String = "", serverProtocol: ServerProtocol? = nil) {
        self.inProgressAccount = inProgressAccount
        self.enteredEmail = enteredEmail
        self.serverProtocol = serverProtocol
    }
}

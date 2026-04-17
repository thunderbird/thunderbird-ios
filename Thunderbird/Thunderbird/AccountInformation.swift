//
//  AcccountInformation.swift
//  Thunderbird
//
//  Created by Ashley Soucar on 8/28/25.
//

import SwiftUI
import Account
import Autoconfiguration

struct AccountInformation: View {
    init(_ path: Binding<NavigationPath>) {
        _path = path
    }

    @Binding var path: NavigationPath
    @Environment(Accounts.self) private var accounts: Accounts
    @Environment(LoginDetails.self) private var loginDetails: LoginDetails
    @State private var showManual: Bool = true
    @State private var emailAddress: String = ""
    @State private var account: Account?
    @State private var config: ClientConfig?
    @State private var password: String = ""
    @State private var error: Error?
    @State private var loginServer: Server = Server(.imap)

    private func refreshAccount() {
        account = emailAddress.isEmailAddress ? Account(emailAddress, provider: config?.emailProvider) : nil
        guard let account = account else { return }
        guard let incomingServer = account.incomingServer else { return }
        loginServer = incomingServer
    }

    var body: some View {
        Form {
            TextEntryWrapper("account_server_settings_email_address_label", "your.email@example.com", $emailAddress)
                #if os(iOS)
            .keyboardType(.emailAddress)
            .submitLabel(.search)
                #endif
            AutoconfigView($config, for: emailAddress)
                .listRowSeparator(.hidden)
            if config != nil && account != nil {
                Button(
                    action: {
                        loginDetails.inProgressAccount = account
                        loginDetails.enteredEmail = emailAddress
                        path.append("ManualAccountSetup")

                    }) {
                        Text("account_server_edit_configuration")
                            .padding(5.5)
                            .frame(maxWidth: .infinity)
                            .underline()

                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .buttonStyle(.plain)
                if account?.incomingServer?.authenticationType != nil {
                    AuthorizationView(
                        $loginServer.authorization,
                        error: $error,
                        for: loginServer.username,
                        authenticationType: loginServer.authenticationType
                    ).onChange(of: loginServer.authorization) {
                        guard var account = account else { return }
                        var incomingServerInfo = account.incomingServer?.clone() ?? Server(.imap)
                        var outgoingServerInfo = account.outgoingServer?.clone() ?? Server(.smtp)
                        incomingServerInfo.authorization = loginServer.authorization
                        outgoingServerInfo.authorization = loginServer.authorization
                        account.servers = [incomingServerInfo, outgoingServerInfo]
                        accounts.set(account)
                    }
                }
            }
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
            //TEMP DEMO BUTTON
            Button(
                action: {
                    account = Account("demoEmail.gmail.com", provider: config?.emailProvider)
                    guard var account = account else { return }
                    let incomingServer = Server(.imap)
                    loginServer = incomingServer
                    var incomingServerInfo = account.incomingServer?.clone() ?? Server(.imap)
                    var outgoingServerInfo = account.outgoingServer?.clone() ?? Server(.smtp)
                    incomingServerInfo.authorization = loginServer.authorization
                    outgoingServerInfo.authorization = loginServer.authorization
                    account.servers = [incomingServerInfo, outgoingServerInfo]
                    accounts.set(account)

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
        .onChange(of: emailAddress, initial: true) {
            refreshAccount()
        }
        .onChange(of: config, initial: true) {
            refreshAccount()
        }
        .scrollContentBackground(.hidden)
        #if os(iOS)
        .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
        #endif
        .navigationTitle("account_server_information_title")
    }
}

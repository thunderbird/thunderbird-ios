//
//  ManualServerSetup.swift
//  Thunderbird
//
//  Created by Ashley Soucar on 8/18/25.
//

import SwiftUI
import Account
import Autoconfiguration

struct ManualServerSetup: View {
    init(_ loginDetails: LoginDetails) {
        let tempAccount = loginDetails.inProgressAccount ?? Account(loginDetails.enteredEmail)
        self.account = tempAccount
        self.manualConfig = loginDetails.inProgressAccount != nil
        self.incomingServer = tempAccount.incomingServer?.clone() ?? Server(.imap)
        self.outgoingServer = tempAccount.outgoingServer?.clone() ?? Server(.smtp)
        self.inSelectedSecurity = tempAccount.incomingServer?.connectionSecurity == .tls
        self.outSelectedSecurity = tempAccount.outgoingServer?.connectionSecurity == .tls
        self.incomingHostname = tempAccount.incomingServer?.hostname ?? ""
        self.incomingPort = tempAccount.incomingServer?.port
        self.outGoingHostname = tempAccount.outgoingServer?.hostname ?? ""
        self.outGoingPort = tempAccount.outgoingServer?.port
    }

    @Environment(Accounts.self) private var accounts: Accounts
    @Environment(LoginDetails.self) private var loginDetails: LoginDetails
    @State private var incomingServer: Server
    @State private var outgoingServer: Server
    @State private var incomingHostname: String
    @State private var incomingPort: Int?
    @State private var outGoingHostname: String
    @State private var outGoingPort: Int?
    @State private var inSelectedSecurity: Bool
    @State private var outSelectedSecurity: Bool
    @State private var manualConfig: Bool
    @State private var account: Account
    @State private var error: Error?

    // MARK: View
    var body: some View {
        Form {
            if loginDetails.serverProtocol == .jmap {
                Section(header: Text("account_server_edit_configuration")) {

                    TextEntryWrapper("account_server_settings_server_label", "server.example.com", $incomingHostname)
                    NumEntryWrapper("account_server_settings_port_label", "443", $incomingPort)
                    Picker("account_server_settings_authentication_label", selection: $incomingServer.authenticationType) {
                        ForEach(AuthenticationType.allCases) { authentication in
                            Text(authentication.text)
                                .tag(authentication)
                        }
                    }
                    AuthorizationView(
                        $incomingServer.authorization,
                        error: $error,
                        for: incomingServer.username,
                        authenticationType: incomingServer.authenticationType
                    )

                    Toggle("account_server_settings_security_label", isOn: $inSelectedSecurity)
                        .tint(.accent)
                        .listRowSeparator(.hidden)

                }

            } else {
                Section(header: Text("account_incoming_server_label")) {

                    TextEntryWrapper("account_server_settings_server_label", "server.example.com", $incomingHostname)
                    NumEntryWrapper("account_server_settings_port_label", "443", $incomingPort)
                    Picker("account_server_settings_authentication_label", selection: $incomingServer.authenticationType) {
                        ForEach(AuthenticationType.allCases) { authentication in
                            Text(authentication.text)
                                .tag(authentication)
                        }
                    }
                    .onChange(of: incomingServer.authenticationType, initial: true) {

                    }
                    AuthorizationView(
                        $incomingServer.authorization,
                        error: $error,
                        for: incomingServer.username,
                        authenticationType: incomingServer.authenticationType
                    )
                    Toggle("account_server_settings_security_label", isOn: $inSelectedSecurity)
                        .tint(.accent)
                        .listRowSeparator(.hidden)

                }
                Section(header: Text("account_outgoing_server_label")) {
                    TextEntryWrapper("account_server_settings_server_label", "server.example.com", $outGoingHostname)
                    NumEntryWrapper("account_server_settings_port_label", "443", $outGoingPort)

                    Picker("account_server_settings_authentication_label", selection: $outgoingServer.authenticationType) {
                        ForEach(AuthenticationType.allCases) { authentication in
                            Text(authentication.text)
                                .tag(authentication)
                        }
                    }
                    .onChange(of: incomingServer.authenticationType, initial: true) {

                    }
                    AuthorizationView(
                        $outgoingServer.authorization,
                        error: $error,
                        for: outgoingServer.username,
                        authenticationType: outgoingServer.authenticationType
                    )
                    Toggle("account_server_settings_security_label", isOn: $outSelectedSecurity)
                        .tint(.accent)
                        .listRowSeparator(.hidden)
                }
            }
            VStack(alignment: HorizontalAlignment.leading) {
                Text("account_setup_tips").bold()
                Text("server_setup_contact")
                Text("server_setup_incoming_tip")
                Text("server_setup_outgoing_tip")
            }
            .font(.caption)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.buttonFillOn)
                    .stroke(.gray, lineWidth: 1)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(
                action: {
                    // TODO: Need validation

                    incomingServer.connectionSecurity = inSelectedSecurity ? ConnectionSecurity.tls : ConnectionSecurity.none
                    incomingServer.hostname = incomingHostname
                    incomingServer.port = incomingPort ?? 443
                    outgoingServer.connectionSecurity = outSelectedSecurity ? ConnectionSecurity.tls : ConnectionSecurity.none
                    outgoingServer.hostname = outGoingHostname
                    outgoingServer.port = outGoingPort ?? 443

                    if loginDetails.serverProtocol == .jmap {
                        account.servers = [
                            incomingServer,
                            incomingServer
                        ]
                    } else {
                        account.servers = [
                            incomingServer,
                            outgoingServer
                        ]
                    }
                    accounts.set(account)
                }) {
                    Text("account_oauth_sign_in_button")
                        .padding(5.5)
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .padding()
        }
        .scrollContentBackground(.hidden)
        #if os(iOS)
        .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
        #endif
        .navigationTitle("account_server_manual_configuration")

    }
}

#Preview("Manual Server Account Setup") {
    @Previewable @State var accounts: Accounts = Accounts()
    @Previewable @State var loginDetails: LoginDetails = LoginDetails()
    ManualServerSetup(loginDetails).environment(accounts).environment(loginDetails)
}

public extension Server {
    func clone() -> Self {
        var server: Self = Server(
            serverProtocol,
            connectionSecurity: connectionSecurity,
            authenticationType: authenticationType,
            username: username,
            hostname: hostname,
            port: port
        )
        switch authorization {
        case .basic(let user, let password): print("basic(user: \(user); password: \(password))")
        case .oauth(let user, let password): print("oauth(user: \(user); password: \(password))")
        case .none: print("none")
        }
        server.authorization = authorization
        return server
    }
}

private extension AuthenticationType {
    var text: String {
        switch self {
        case .oAuth2: description
        default: description.capitalized
        }
    }
}

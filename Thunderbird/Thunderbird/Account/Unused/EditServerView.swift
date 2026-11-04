// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI

/// Older server editor with protocol, host, port, username, security and authentication fields.
///
/// Only used by ``EditAccountView``, which isn't currently shown in the app.
struct EditServerView: View {
    /// - Parameters:
    ///   - server: Server to edit.
    ///   - account: Account whose sign-in is edited.
    init(_ server: Binding<Server>, _ account: Binding<Account>) {
        _server = server
        _account = account
    }

    @Binding private var server: Server
    @Binding private var account: Account
    @State private var password: String = ""
    @State private var error: Error?

    // MARK: View
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Server Protocol")
                Spacer()
                Picker("Server Protocol", selection: $server.serverProtocol) {
                    ForEach(ServerProtocol.allCases) { serverProtocol in
                        Text(serverProtocol.description)
                            .tag(serverProtocol)
                    }
                }
            }
            .padding(.bottom)
            VStack(alignment: .leading) {
                Text("Host Name and Port")
                HStack {
                    TextField("mail.example.com", text: $server.hostname)
                        #if os(iOS)
                    .keyboardType(.URL)
                        #endif
                    TextField("123", value: $server.port, formatter: NumberFormatter())
                        #if os(iOS)
                    .keyboardType(.numberPad)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 72.0)
                }
            }
            .padding(.bottom)
            VStack(alignment: .leading) {
                Text("User Name")
                TextField("user@example.com", text: $server.username)
                    #if os(iOS)
                .keyboardType(.emailAddress)
                    #endif
            }
            .padding(.bottom)
            HStack {
                Text("Connection Security")
                Spacer()
                Picker("Connection Security", selection: $server.connectionSecurity) {
                    ForEach(Server.ConnectionSecurity.allCases, id: \.self) {
                        Text($0.description.uppercased())
                    }
                }
            }
            HStack {
                Text("Authentication Type")
                Spacer()
                Picker("Authentication Type", selection: $server.authenticationType) {
                    ForEach(AuthenticationType.allCases) { authentication in
                        Text(authentication.text)
                            .tag(authentication)
                    }
                }
                .onChange(of: server.authenticationType, initial: true) {

                }
            }
            AuthorizationView($account, error: $error, isEditable: true)
        }
        .textFieldStyle(.roundedBorder)
        #if os(iOS)
        .autocapitalization(.none)
        #endif
        .autocorrectionDisabled()
        .labelsHidden()
    }
}

#Preview("Edit Server View") {
    @Previewable @State var server: Server = Server(.imap, username: "user@example.com")
    @Previewable @State var account: Account = Account("user@example.com")

    ScrollView {
        EditServerView($server, $account)
            .padding()
    }
}

/// Extends `AuthenticationType` with display names for pickers.
private extension AuthenticationType {
    /// The type's description, capitalized except for OAuth2.
    var text: String {
        switch self {
        case .oAuth2: description
        default: description.capitalized
        }
    }
}

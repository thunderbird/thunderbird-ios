import Account
import SwiftUI

struct EditServerView: View {
    init(_ server: Binding<Server>) {
        _server = server
    }

    @Binding private var server: Server
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
            AuthorizationView(
                $server.authorization,
                error: $error,
                for: server.username,
                authenticationType: server.authenticationType
            )
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

    ScrollView {
        EditServerView($server)
            .padding()
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

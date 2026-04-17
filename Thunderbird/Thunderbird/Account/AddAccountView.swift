import Account
import Autoconfiguration
import SwiftUI

struct AddAccountView: View {
    init(_ emailAddress: String = "") {
        self.emailAddress = emailAddress
    }

    @Environment(Accounts.self) private var accounts: Accounts
    @Environment(\.dismiss) var dismiss
    @State private var showManual: Bool = false
    @State private var emailAddress: String
    @State private var account: Account?
    @State private var config: ClientConfig?
    @State private var error: Error?

    private func refreshAccount() {
        account = emailAddress.isEmailAddress ? Account(emailAddress, provider: config?.emailProvider) : nil
    }

    // MARK: View
    var body: some View {
        ScrollView {
            VStack(spacing: 17.0) {
                TextField(text: $emailAddress) {
                    Text("Email Address")
                }
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                #if os(iOS)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .submitLabel(.search)
                #endif

                // Portable autoconfig widget/view
                AutoconfigView($config, for: emailAddress)
            }
            .padding()
        }
        .navigationTitle("Add Account")
        .onChange(of: emailAddress, initial: true) {
            refreshAccount()
        }
        .onChange(of: config, initial: true) {
            refreshAccount()
        }
        .toolbar {
            Button(action: {
                guard let account else { return }
                accounts.set(account)
                dismiss()
            }) {
                Text("Save")
            }
            .disabled(account == nil)
        }
    }
}

#Preview("Add Account View") {
    @Previewable @State var accounts: Accounts = Accounts()

    AddAccountView()
        .environment(accounts)
}

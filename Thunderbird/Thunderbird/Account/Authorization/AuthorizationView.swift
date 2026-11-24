// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import AuthenticationServices
import Autoconfiguration
import BoltUI
import SwiftUI

/// Sign-in controls for an account: an authentication type picker, then an OAuth2 sign-in button or a password field.
struct AuthorizationView: View {
    /// - Parameters:
    ///   - account: Account whose authentication type and credentials are edited.
    ///   - error: Set to any sign-in error.
    ///   - isEditable: Whether to show the authentication type picker.
    init(_ account: Binding<Account>, error: Binding<Error?> = .constant(nil), isEditable: Bool = true) {
        self.isEditable = isEditable
        _account = account
        _error = error
    }

    @Binding private var account: Account
    @Binding private var error: Error?
    @State private var password: String = ""
    private let isEditable: Bool

    // MARK: View
    var body: some View {
        VStack(spacing: .spacing(.compact)) {
            if isEditable {
                AuthenticationTypeView($account.authenticationType)
            }
            switch account.authenticationType {
            case .oauth2:
                OAuthButton($account, error: $error)
            case .password:
                PasswordField("account_server_settings_authentication_password_cleartext", text: $password)
                    // TODO: Store the password when the account is saved, not on every keystroke, and skip an empty password (#606).
                    .onChange(of: password) { account.password = password }
                    .onAppear { password = account.password }
            case .none:
                EmptyView()
            }
        }
    }
}

#Preview("Authorization View") {
    @Previewable @State var account: Account = .example
    @Previewable @State var error: Error?

    AuthorizationView($account, error: $error)
        .padding()
    Divider()
    AuthorizationView($account, error: $error, isEditable: false)
        .padding()
}

/// Picker for an account's authentication type.
struct AuthenticationTypeView: View {
    /// - Parameter authenticationType: The selected authentication type.
    init(_ authenticationType: Binding<AuthenticationType>) {
        _authenticationType = authenticationType
    }

    @Binding private var authenticationType: AuthenticationType

    // MARK: View
    var body: some View {
        Picker("account_server_settings_authentication_label", selection: $authenticationType) {
            ForEach(AuthenticationType.allCases, id: \.self) {
                Text($0.description.capitalized(.sentence))
            }
        }
        .formInput("account_server_settings_authentication_label", layout: .horizontal)
    }
}

#Preview("Authentication Type View") {
    @Previewable @State var authenticationType: AuthenticationType = .oauth2

    AuthenticationTypeView($authenticationType)
        .onChange(of: authenticationType, initial: true) {
            print(authenticationType)
        }
        .padding()
}

/// Extends `Account` with preview data and password access for ``AuthorizationView``.
private extension Account {
    /// Example account with an OAuth2 IMAP server, for previews.
    static var example: Self {
        Account(
            identities: [
                "example@thunderbird.net"
            ],
            servers: [
                Server(.imap, authenticationType: .oauth2)
            ]
        )
    }

    /// The password from the account's basic authorization, or an empty string.
    ///
    /// Setting it replaces the authorization with basic credentials for the primary email address. It does nothing when the account has no email address.
    var password: String {
        set {
            guard let emailAddress else { return }
            authorization = .basic(user: emailAddress.value, password: newValue)
        }
        get {
            switch authorization {
            case .basic(_, let password): password
            default: ""
            }
        }
    }
}

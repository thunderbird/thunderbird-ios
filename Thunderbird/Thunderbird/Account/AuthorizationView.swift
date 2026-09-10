// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import AuthenticationServices
import Autoconfiguration
import SwiftUI

struct AuthorizationView: View {
    let username: String
    let authenticationType: AuthenticationType

    init(
        _ authorization: Binding<Authorization>,
        error: Binding<Error?>,
        for username: String,
        authenticationType: AuthenticationType = .oAuth2,
        authConfig: Binding<OAuth2.Request?> = .constant(nil)
    ) {
        self.username = username
        self.authenticationType = authenticationType
        _authorization = authorization
        _error = error
        _authConfig = authConfig
        switch authorization.wrappedValue {
        case .basic(_, let password):
            self.password = password
        case .oauth(_, let token, let refreshToken):
            self.token = token
            self.refreshToken = refreshToken
        case .none:
            break
        }
    }

    @Binding private var authorization: Authorization
    @Binding private var authConfig: OAuth2.Request?
    @Binding private var error: Error?
    @State private var password: String = ""
    @State private var token: Token?
    @State private var refreshToken: Token?

    // MARK: View
    var body: some View {
        switch authenticationType {
        case .password:
            SecureField("Password", text: $password)
                .onChange(of: password) {
                    authorization = .basic(user: username, password: password)
                }
        case .oAuth2:
            OAuthButton(username, token: $token, refreshToken: $refreshToken, authConfig: $authConfig, error: $error)
                .onChange(of: token, initial: true) {
                    if let token, let refreshToken {
                        authorization = .oauth(user: username, token: token, refresh: refreshToken)
                    } else {
                        authorization = .none
                    }
                }
        case .none:
            EmptyView()
        }
    }
}

#Preview("Authorization View") {
    @Previewable @State var authorization: Authorization = .none
    @Previewable @State var error: Error?
    @Previewable @State var auth: OAuth2.Request? = .google

    AuthorizationView($authorization, error: $error, for: "example@thunderbird.net", authConfig: $auth)
        .padding()
}

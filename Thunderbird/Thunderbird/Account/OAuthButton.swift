// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import AuthenticationServices
import Autoconfiguration
import SwiftUI

struct OAuthButton: View {
    let emailAddress: String

    init(
        _ emailAddress: String = "",
        token: Binding<Token?>,
        refreshToken: Binding<Token?>,
        authConfig: Binding<OAuth2.Request?>,
        error: Binding<Error?>
    ) {
        self.emailAddress = emailAddress
        _token = token
        _error = error
        _refreshToken = refreshToken
        _authConfig = authConfig
    }

    @Binding private var token: Token?
    @Binding private var error: Error?
    @Binding private var refreshToken: Token?
    @Binding private var authConfig: OAuth2.Request?
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession

    private func authenticate() async {
        let retries = 2
        var hasSucceeded = false
        for _ in 0..<retries {
            do {
                error = nil
                guard let authConfig else { return }
                if !hasSucceeded {
                    let pkce = OAuth2.PKCE()
                    let authURL: URL = try await webAuthenticationSession.authenticate(
                        using: authConfig.authURL(hint: emailAddress, pkce: pkce),
                        callback: .customScheme("\(Bundle.main.schemes.first!)"), additionalHeaderFields: [:])
                    let queryItems = URLComponents(string: authURL.absoluteString)?.queryItems
                    let code = (queryItems?.filter({ $0.name == "code" }).first?.value)!
                    await getToken(code: code, pkce: pkce)
                    hasSucceeded = true
                }
            } catch {
                self.error = error
            }
        }

    }

    private func configure() async {
        do {
            error = nil
            authConfig = try await OAuth2.request(emailAddress)
        } catch {
            self.error = error
        }
    }

    private func getToken(code: String, pkce: OAuth2.PKCE) async {
        let retries = 3
        error = nil
        guard let authConfig else { return }
        for _ in 0..<retries {
            do {
                let tokenRequest = try URLRequest.token(authConfig, code: code, pkce: pkce)
                let (data, _) = try await URLSession.shared.data(for: tokenRequest)
                let response = try JSONDecoder().decode(TokenResponse.self, from: data)
                token = .bearer(response.accessToken, Date(timeIntervalSinceNow: TimeInterval(response.expiresIn)))
                refreshToken = .refresh(response.refreshToken)
            } catch {
                self.error = error
            }
            break
        }
    }

    // MARK: View
    var body: some View {
        Button(action: {
            Task {
                await authenticate()
            }
        }) {
            Text("account_oauth_sign_in_button")
        }
        .buttonStyle(.borderedProminent)
        .tint(.accent)
        .disabled(authConfig == nil)
        .task {
            await configure()
        }
    }
}

#Preview("OAuth Button") {
    @Previewable @State var token: Token?
    @Previewable @State var refreshToken: Token?
    @Previewable @State var error: Error?
    @Previewable @State var authConfig: OAuth2.Request?

    OAuthButton(
        "example@thunderbird.net",
        token: $token,
        refreshToken: $refreshToken,
        authConfig: $authConfig,
        error: $error
    )
}

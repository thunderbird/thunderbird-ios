// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import AuthenticationServices
import Autoconfiguration
import SwiftUI

/// Shows an account's OAuth2 status, with a button to sign in through the provider's web page, or to sign out.
///
/// When it appears, it looks for a configuration matching the account's MX hosts; sign-in stays disabled if none matches. Signing in runs an authorization-code flow with PKCE and stores the tokens as the account's authorization.
struct OAuthButton: View {
    /// - Parameters:
    ///   - account: Account to sign in; its authorization is replaced when sign-in succeeds or the user signs out.
    ///   - error: Set to any configuration or sign-in error.
    ///   - action: Called after the provider's sign-in page returns, even if the token exchange then fails.
    init(_ account: Binding<Account>, error: Binding<Error?> = .constant(nil), action: @escaping @MainActor () -> Void = {}) {
        self.action = action
        _account = account
        _error = error
    }

    @Environment(\.webAuthenticationSession) private var webAuthenticationSession: WebAuthenticationSession
    @Binding private var account: Account
    @Binding private var error: Error?
    @State private var authConfig: OAuth2.Configuration?
    private let action: () -> Void

    /// Find the OAuth2 configuration matching the account's email address.
    private func configure() async {
        error = nil
        do {
            guard let emailAddress: EmailAddress = account.emailAddress else {
                throw AccountError.emailAddressNotFound
            }
            authConfig = try await OAuth2.configuration(emailAddress.value)

        } catch {
            self.error = error
        }
    }

    /// Present the provider's sign-in page, then exchange the returned code for tokens.
    ///
    /// - Note: Errors ``AccountError`` can't represent, such as the user cancelling, clear `error` rather than setting it.
    // TODO: Tell user cancellation apart from real failures, and show the failures (#605).
    private func authenticate() async {
        error = nil
        do {
            guard let emailAddress: EmailAddress = account.emailAddress else {
                throw AccountError.emailAddressNotFound
            }
            guard let authConfig else {
                throw AccountError.emailAddressNotSupported
            }
            // TODO: Send an OAuth2 `state` parameter and check it on the callback. PKCE covers most of the risk.
            let pkce: OAuth2.PKCE = OAuth2.PKCE()
            let authURL: URL = try await webAuthenticationSession.authenticate(
                using: authConfig.authURL(hint: emailAddress.value, pkce: pkce),
                callback: .customScheme("\(Bundle.main.schemes.first!)"), additionalHeaderFields: [:]
            )
            let code: String = try authURL.code
            await getToken(code: code, pkce: pkce)
            action()
        } catch {
            self.error = AccountError(error)
        }
    }

    /// Exchange an authorization code for tokens and store them as the account's authorization.
    ///
    /// - Parameters:
    ///   - code: Authorization code from the sign-in callback.
    ///   - pkce: The PKCE pair whose challenge was sent with the sign-in request.
    private func getToken(code: String, pkce: OAuth2.PKCE) async {
        error = nil
        do {
            guard let emailAddress: EmailAddress = account.emailAddress else {
                throw AccountError.emailAddressNotFound
            }
            guard let authConfig else {
                throw AccountError.emailAddressNotSupported
            }
            let request: URLRequest = try URLRequest.token(authConfig, code: code, pkce: pkce)
            let data: Data = try await URLSession.shared.data(for: request).0
            let response: TokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            let refreshToken: Token = .refresh(response.refreshToken)
            let token: Token = .bearer(
                response.accessToken,
                Date(timeIntervalSinceNow: TimeInterval(response.expiresIn))
            )
            account.authorization = .oauth(user: emailAddress.value, token: token, refresh: refreshToken)
        } catch {
            self.error = error
        }
    }

    // MARK: View
    var body: some View {
        HStack {
            Text(account.oauthStatus.localizedStringKey)
            Spacer()
            switch account.oauthStatus {
            case .validToken:
                Button("account_sign_out_button", role: .destructive) {
                    account.authorization = .none
                }
                .buttonStyle(.borderedProminent)
            case .expiredToken, .emptyToken:
                Button(action: {
                    Task { await authenticate() }
                }) {
                    Text("account_oauth_sign_in_button")
                }
                .buttonStyle(.borderedProminent)
                .disabled(authConfig == nil)
            }
        }
        .task {
            await configure()
        }
    }
}

#Preview("OAuth Button") {
    @Previewable @State var account: Account = Account("example@thunderbird.net")
    @Previewable @State var error: Error?

    OAuthButton($account, error: $error) {
        print(account.authorization)
    }
    .padding()
}

/// Extends `Account` with OAuth2 sign-in state for ``OAuthButton``.
private extension Account {
    /// Whether the account has an OAuth2 token, and whether it has expired.
    enum OAuthStatus {
        /// The account has an unexpired OAuth2 token.
        case validToken
        /// The account's OAuth2 token has expired.
        case expiredToken
        /// The account has no OAuth2 authorization.
        case emptyToken

        /// Localization key describing the status.
        var localizedStringKey: LocalizedStringKey {
            switch self {
            case .validToken: "account_oauth_token_valid"
            case .expiredToken: "account_oauth_token_expired"
            case .emptyToken: "account_oauth_token_empty"
            }
        }
    }

    /// The account's OAuth2 token status. Accounts with any other kind of authorization are `emptyToken`.
    var oauthStatus: OAuthStatus {
        switch authorization {
        case .oauth: authorization.isExpired ? .expiredToken : .validToken
        default: .emptyToken
        }
    }
}

/// Extends `URL` with OAuth2 help links and sign-in callback parsing.
private extension URL {
    /// Mozilla's OAuth2 support article. Not currently used.
    // TODO: Link to this article from the OAuth2 sign-in error, or remove it.
    static let help: Self = Self(string: "https://support.mozilla.org/kb/tb-oauth")!

    /// The `code` query item from an OAuth2 sign-in callback URL.
    ///
    /// - Throws: `URLError(.badServerResponse)` if the URL has no `code` query item.
    var code: String {
        get throws {
            guard let queryItems: [URLQueryItem] = URLComponents(string: absoluteString)?.queryItems,
                let code: String = queryItems.filter({ $0.name == "code" }).first?.value
            else {
                throw URLError(.badServerResponse)
            }
            return code
        }
    }
}

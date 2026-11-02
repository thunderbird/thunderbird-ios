// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Autoconfiguration
import Foundation

/// Extends `OAuth2.Configuration` with Thunderbird's client configurations for the email providers that support OAuth2 sign-in.
///
/// The app registers ``allCases`` as `OAuth2.configurations` at launch, so `OAuth2.configuration(_:)` can match an
/// address's MX hosts against each configuration's `hosts`.
///
/// - Important: Each redirect URI is built from the app's first URL scheme, so these crash if the app declares none.
extension OAuth2.Configuration: @retroactive CaseIterable {

    // MARK: AOL
    /// AOL Mail, matching AOL's mail hosts and Yahoo's `yahoodns.net` MX hosts.
    static var aol: Self {
        try! Self(
            authURI: "https://api.login.aol.com/oauth2/request_auth",
            tokenURI: "https://api.login.aol.com/oauth2/get_token",
            redirectURI: "\(Bundle.main.schemes.first!)://oauth2",
            responseType: "code",
            scope: [
                "mail-w"
            ],
            clientID: "dj0yJmk9aVN2UzU1S3N6UWlGJmQ9WVdrOVRXTnlla056U2swbWNHbzlNQT09JnM9Y29uc3VtZXJzZWNyZXQmc3Y9MCZ4PTBi",
            hosts: [
                "imap.mail.aol.com",
                "smtp.mail.aol.com",
                "yahoodns.net"
            ]
        )
    }

    // MARK: Fastmail
    /// Fastmail, matching `fastmail.com` and its `messagingengine.com` MX hosts.
    static var fastmail: Self {
        try! Self(
            authURI: "https://api.fastmail.com/oauth/authorize",
            tokenURI: "https://api.fastmail.com/oauth/refresh",
            redirectURI: "\(Bundle.main.schemes.first!)://oauth2redirect",
            responseType: "code",
            scope: [
                "https://www.fastmail.com/dev/protocol-imap",
                "https://www.fastmail.com/dev/protocol-smtp"
            ],
            clientID: "353e41ae",
            hosts: [
                "messagingengine.com",
                "fastmail.com"
            ]
        )
    }

    // MARK: Google
    /// Gmail and Google Workspace, matching `gmail.com`, `googlemail.com` and `google.com` hosts.
    static var google: Self {
        try! Self(
            authURI: "https://accounts.google.com/o/oauth2/v2/auth",
            tokenURI: "https://oauth2.googleapis.com/token",
            redirectURI: "\(Bundle.main.schemes.first!):/oauth2redirect",
            responseType: "code",
            scope: [
                "https://mail.google.com/"
            ],
            clientID: "769997220831-n207vus74snfmeoeagphatkrco9ckb7s.apps.googleusercontent.com",
            hosts: [
                "googlemail.com",
                "google.com",
                "gmail.com"
            ]
        )
    }

    // MARK: Microsoft
    /// Outlook and Microsoft 365, matching `outlook.com` and `office365.com` hosts.
    static var microsoft: Self {
        try! Self(
            authURI: "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
            tokenURI: "https://login.microsoftonline.com/common/oauth2/v2.0/token",
            redirectURI: "msauth.\(Bundle.main.schemes.first!)://auth",
            responseType: "code",
            scope: [
                "profile",
                "openid",
                "email",
                "https://outlook.office.com/IMAP.AccessAsUser.All",
                "https://outlook.office.com/SMTP.Send",
                "offline_access"
            ],
            clientID: "22c6c0b6-8265-4475-9cb8-b8f225837d93",
            hosts: [
                "office365.com",
                "outlook.com"
            ]
        )
    }

    // MARK: Thundermail
    /// Thundermail, matching `thundermail.com` and `tb.pro` hosts.
    static var thundermail: Self {
        try! Self(
            authURI: "https://auth.tb.pro/realms/tbpro/protocol/openid-connect/auth",
            tokenURI: "https://auth.tb.pro/realms/tbpro/protocol/openid-connect/token",
            redirectURI: "\(Bundle.main.schemes.first!):/oauth2redirect",
            responseType: "code",
            scope: [
                "openid",
                "profile",
                "email",
                "offline_access"
            ],
            clientID: "mobile-ios-thunderbird",
            hosts: [
                "tb.pro",
                "thundermail.com"
            ]
        )
    }

    // MARK: Yahoo
    /// Yahoo Mail, matching Yahoo's mail hosts and its `yahoodns.net` MX hosts.
    static var yahoo: Self {
        try! Self(
            authURI: "https://api.login.yahoo.com/oauth2/request_auth",
            tokenURI: "https://api.login.yahoo.com/oauth2/get_token",
            redirectURI: "\(Bundle.main.schemes.first!)://oauth2",
            responseType: "code",
            scope: [
                "mail-w"
            ],
            clientID: "dj0yJmk9emZqcDA4Q2w3QW9GJmQ9WVdrOVpYaG9Vak5KYjA4bWNHbzlNQT09JnM9Y29uc3VtZXJzZWNyZXQmc3Y9MCZ4PTA4",
            hosts: [
                "imap.mail.yahoo.com",
                "smtp.mail.yahoo.com",
                "yahoodns.net"
            ]
        )
    }

    // MARK: CaseIterable
    /// Every provider configuration, in alphabetical order.
    public static var allCases: [Self] {
        [
            .aol,
            .fastmail,
            .google,
            .microsoft,
            .thundermail,
            .yahoo
        ]
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Autoconfiguration
import Foundation

/// Thunderbird iOS specific OAuth2 Request objects for expected email providers
/// > Note: TODO: Replace current Android ids and secrets with iOS specific ones as they are received
extension OAuth2.Request: @retroactive CaseIterable {

    // MARK: AOL
    static var aol: Self {
        try! Self(
            authURI: "https://api.login.aol.com/oauth2/request_auth",
            tokenURI: "https://api.login.aol.com/oauth2/get_token",
            redirectURI: "\(Bundle.main.schemes.first!)://oauth2redirect",
            responseType: "code",
            scope: [
                "mail-w"
            ],
            clientID: "dj0yJmk9MVJGcHpSejNUcTU3JmQ9WVdrOWMwMHhjSFZqTkhRbWNHbzlNQT09JnM9Y29uc3VtZXJzZWNyZXQmc3Y9MCZ4PWNk",
            hosts: [
                "aol.com"
            ]
        )
    }

    // MARK: Fastmail
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
    static var google: Self {
        try! Self(
            authURI: "https://accounts.google.com/o/oauth2/v2/auth",
            tokenURI: "https://oauth2.googleapis.com/token",
            redirectURI: "\(Bundle.main.schemes.first!):/oauth2redirect",
            responseType: "code",
            scope: [
                "https://mail.google.com/"
            ],
            clientID: "560629489500-no2mlau7e4vn3psh5esaiodgri09jrj9.apps.googleusercontent.com",
            hosts: [
                "googlemail.com",
                "google.com",
                "gmail.com"
            ]
        )
    }

    // MARK: Microsoft
    static var microsoft: Self {
        try! Self(
            authURI: "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
            tokenURI: "https://login.microsoftonline.com/common/oauth2/v2.0/token",
            redirectURI: "msauth://\(Bundle.main.schemes.first!)/eaXDuh6T3KFWjcJhsoaObT9OayU%3D",
            responseType: "code",
            scope: [
                "profile",
                "openid",
                "email",
                "https://outlook.office.com/IMAP.AccessAsUser.All",
                "https://outlook.office.com/SMTP.Send",
                "offline_access"
            ],
            clientID: "e6f8716e-299d-4ed9-bbf3-453f192f44e5",
            hosts: [
                "office365.com",
                "outlook.com"
            ]
        )
    }

    // MARK: Thundermail
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
    static var yahoo: Self {
        try! Self(
            authURI: "https://api.login.yahoo.com/oauth2/request_auth",
            tokenURI: "https://api.login.yahoo.com/oauth2/get_token",
            redirectURI: "\(Bundle.main.schemes.first!)://oauth2redirect",
            responseType: "code",
            scope: [
                "mail-w"
            ],
            clientID: "dj0yJmk9bXRhTkZod2xmY3JrJmQ9WVdrOVUyUTRXRGQ0Tlc4bWNHbzlNQT09JnM9Y29uc3VtZXJzZWNyZXQmc3Y9MCZ4PTkx",
            hosts: [
                "yahoo.com"
            ]
        )
    }

    // MARK: CaseIterable
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

extension OAuth2 {
    static func request(_ emailAddress: String) async throws -> Self.Request {
        let records: [MXRecord] = try await DNSResolver.queryMX(emailAddress)
        for record in records {
            for request in Request.allCases {
                guard request.matches(record.host) else { continue }
                return request
            }
        }
        throw URLError(.unsupportedURL)
    }
}

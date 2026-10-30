// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

public struct ClientConfig: Decodable, Equatable {
    public let emailProvider: EmailProvider?
    public let oAuth2: OAuth2?
    public let webMail: WebMail?

    // MARK: Equatable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.emailProvider?.domain == rhs.emailProvider?.domain || lhs.webMail?.loginPage == rhs.webMail?.loginPage
    }
}

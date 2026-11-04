// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Client configuration for an email account, decoded from the Autoconfig JSON produced by ``XMLToJSONParser``.
///
/// Every section is optional because providers publish only the parts they support.
public struct ClientConfig: Decodable, Equatable {
    /// Provider details and incoming/outgoing server settings.
    public let emailProvider: EmailProvider?
    /// OAuth2 endpoints advertised by the provider, if any.
    public let oAuth2: OAuth2?
    /// Web mail login page, if any.
    public let webMail: WebMail?

    // MARK: Equatable
    /// Two configurations are considered equal when they share a provider domain **or** a web mail login page.
    ///
    /// This is an identity match, not a comparison of every field; servers and OAuth2 settings are ignored.
    /// Note that two configurations that both lack a provider and web mail compare equal (`nil == nil`).
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.emailProvider?.domain == rhs.emailProvider?.domain || lhs.webMail?.loginPage == rhs.webMail?.loginPage
    }
}

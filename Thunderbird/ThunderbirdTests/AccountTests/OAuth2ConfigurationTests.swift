// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Autoconfiguration
import Foundation
import Testing
@testable import Thunderbird

struct OAuth2ConfigurationTests {
    //Expect: Use the URL scheme the sign-in sheet listens for, so the provider's redirect comes back to the app.
    //Case: For every OAuth2 provider the app registers at launch (AOL, Fastmail, Google, Microsoft, Thundermail, Yahoo).
    //Example: How a user hits this with Microsoft:
    //  1. They add an Outlook, Hotmail or Microsoft 365 address and tap Sign in.
    //  2. `OAuthButton` opens Microsoft's sign-in page in an `ASWebAuthenticationSession`, listening only for redirects
    //     to `net.thunderbird.ios`, the app's first URL scheme.
    //  3. After they sign in, Microsoft redirects to the configuration's redirect URI,
    //     `msauth.net.thunderbird.ios://auth?code=…`, which has a different scheme.
    //  4. The session doesn't recognize that redirect, so it never hands the code back. The app can't exchange it for
    //     tokens and the account can't be signed in.
    //  The other providers' redirect URIs already use `net.thunderbird.ios`, so this test fails only for Microsoft.
    @Test(arguments: OAuth2.Configuration.allCases)
    func redirectURI_usesSignInCallbackScheme_whenProviderIsRegistered(_ configuration: OAuth2.Configuration) {
        // Arrange
        let expected = Bundle.main.schemes.first  // The callback scheme `OAuthButton.authenticate()` passes to the session

        // Act
        let actual = URL(string: configuration.redirectURI)?.scheme

        // Assert
        #expect(actual == expected, "Redirect URI \(configuration.redirectURI) won't return to the sign-in sheet")
    }
}

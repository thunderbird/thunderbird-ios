// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Autoconfiguration
import Foundation
import Testing
@testable import Thunderbird

struct OAuth2ConfigurationTests {
    //Expect: Use a callback scheme the app registers in its Info.plist.
    //Case: For every OAuth2 provider the app registers at launch (AOL, Fastmail, Google, Microsoft, Thundermail, Yahoo).
    //Example: After signing in, the provider redirects to the configuration's redirect URI, and `OAuthButton` listens
    //  for that URI's scheme (`callbackScheme`). The redirect URIs are built from the app's URL schemes, so reordering
    //  or removing a scheme in Info.plist could produce a redirect the app doesn't own, and sign-in would hang
    //  waiting for it. Before the fix, the button always listened for the first scheme, so Microsoft's
    //  `msauth.net.thunderbird.ios://auth` redirect was never caught.
    @Test(arguments: OAuth2.Configuration.allCases)
    func callbackScheme_isRegisteredByApp_whenProviderIsRegistered(_ configuration: OAuth2.Configuration) {
        // Arrange
        let expected = Bundle.main.schemes

        // Act
        let actual = configuration.callbackScheme

        // Assert
        #expect(expected.contains(actual), "Redirect URI \(configuration.redirectURI) uses a scheme the app doesn't register")
    }

    //Expect: Listen for Microsoft's own `msauth.` scheme, not the app's first URL scheme.
    //Case: When the provider is Microsoft (Outlook, Hotmail, Microsoft 365), whose iOS redirect URIs must use the
    //  `msauth.<bundle ID>://auth` format.
    //Example: This is the case that was broken. Listening for `net.thunderbird.ios` meant Microsoft's redirect to
    //  `msauth.net.thunderbird.ios://auth?code=…` never reached the app, so Microsoft accounts couldn't sign in.
    @Test func callbackScheme_usesMSAuthScheme_whenProviderIsMicrosoft() {
        // Arrange
        let input = OAuth2.Configuration.microsoft
        let expected = "msauth.net.thunderbird.ios"

        // Act
        let actual = input.callbackScheme

        // Assert
        #expect(actual == expected)
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import NIOCore

/// The reason a server gives for rejecting an OAuth access token during `AUTHENTICATE`.
///
/// SASL forbids additional data in an unsuccessful authentication outcome
/// ([RFC 4422, section 3.6](https://www.rfc-editor.org/rfc/rfc4422#section-3.6)), so the tagged `NO` that ends a
/// failed `AUTHENTICATE` can't say why the token was rejected. The OAuth mechanisms send the reason one step earlier
/// instead, as a JSON object in a server challenge (a `+` continuation request):
///
/// ```
/// C: A01 AUTHENTICATE XOAUTH2 dXNlcj1zb21ldXNlckBleGFtcGxlLmNvbQFhdXRoPUJlYXJlciB5YTI5…
/// S: + eyJzdGF0dXMiOiI0MDEiLCJzY2hlbWVzIjoiYmVhcmVyIG1hYyIsInNjb3BlIjoiaHR0cHM6Ly9tYWlsLmdvb2dsZS5jb20vIn0K
/// C:
/// S: A01 NO SASL authentication failed
/// ```
///
/// Base64-decoded, the challenge above is `{"status":"401","schemes":"bearer mac","scope":"https://mail.google.com/"}`.
/// `AuthenticationFailure` is that object, decoded.
///
/// The two OAuth mechanisms agree on `status` and `scope` and differ in the rest:
///
/// | Key | `OAUTHBEARER` | `XOAUTH2` |
/// |---|---|---|
/// | `status` | Required; an OAuth error code such as `invalid_token` | A numeric status such as `401` |
/// | `scope` | Optional | Sent |
/// | `schemes` | Not defined | Sent |
/// | `openid-configuration` | Optional | Not defined |
///
/// `OAUTHBEARER` is specified by [RFC 7628, section 3.2.2](https://www.rfc-editor.org/rfc/rfc7628#section-3.2.2);
/// `XOAUTH2` by Google's [XOAUTH2 protocol](https://developers.google.com/workspace/gmail/imap/xoauth2-protocol)
/// document.
///
/// - Note: None of the values are secret. The object never contains the token that was rejected.
public struct AuthenticationFailure: CustomStringConvertible, Decodable, Equatable, Sendable {
    /// The authorization error code.
    ///
    /// The meaning depends on the mechanism: `OAUTHBEARER` servers send a code from the IANA OAuth Extensions Error
    /// Registry such as `invalid_token`; `XOAUTH2` servers send a numeric status as a string, such as `401`.
    /// Treat it as an opaque string for display and logging, not as something to branch on across providers.
    public let status: String

    /// An OAuth scope that is valid for the service; `nil` when the server didn't name one.
    ///
    /// For `OAUTHBEARER`, a missing scope implies that the server expects an unscoped token.
    public let scope: String?

    /// The token schemes the server accepts, such as `bearer`; `nil` unless the server speaks `XOAUTH2`.
    public let schemes: String?

    /// The URL of the provider's OpenID discovery document; `nil` unless an `OAUTHBEARER` server chose to send it.
    ///
    /// Kept as the string the server sent, so that a malformed URL doesn't discard the rest of the error result.
    public let openIDConfiguration: String?

    /// Decode the error result from a server challenge.
    ///
    /// Returns `nil` when the challenge isn't a JSON object with a string `status`. That is expected, not an error:
    /// a challenge is only an OAuth error result by convention, and a server is free to send something else
    /// (an empty challenge, for one).
    ///
    /// - Parameter challenge: The bytes of the challenge. NIOIMAP has already base64-decoded them by the time it
    ///   delivers `Response.authenticationChallenge`, so this is the raw JSON.
    init?(_ challenge: ByteBuffer) {
        guard let failure: Self = try? JSONDecoder().decode(Self.self, from: Data(challenge.readableBytesView)) else {
            return nil
        }
        self = failure
    }

    // MARK: CustomStringConvertible
    public var description: String {
        guard let scope, !scope.isEmpty else {
            return status
        }
        return "\(status), scope: \(scope)"
    }

    private enum CodingKeys: String, CodingKey {
        case status, scope, schemes
        case openIDConfiguration = "openid-configuration"
    }
}

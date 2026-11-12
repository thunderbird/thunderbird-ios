// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import NIOCore
import NIOIMAPCore

/// SASL credential for use with `IMAPClient.authenticate`
///
/// Generates appropriate `AuthenticationMechanism` and `InitialResponse` for [IMAP AUTHENTICATE SASL-IR](https://www.rfc-editor.org/info/rfc4959)
public enum Authentication: CustomStringConvertible, Equatable, Sendable {
    public typealias Mechanism = AuthenticationMechanism

    case oauthbearer(_ user: String, token: String)
    case plain(_ user: String, password: String)
    case xoauth2(_ user: String, token: String)

    public var mechanism: Mechanism {
        switch self {
        case .oauthbearer: .oauthBearer
        case .plain: .plain
        case .xoauth2: .xoauth2
        }
    }

    public var user: String {
        switch self {
        case .oauthbearer(let user, _), .plain(let user, _), .xoauth2(let user, _): user
        }
    }

    var initialResponse: InitialResponse {
        get throws {
            var data: Data = Data()
            switch self {
            case .oauthbearer(let user, let token):
                // The user goes in the GS2 header, where "," and "=" have meaning; see `saslName`
                data = Data("n,a=\(user.saslName),".utf8) + Data([1]) + Data("auth=Bearer \(token)".utf8) + Data([1]) + Data([1])
            case .plain(let user, let password):
                data = Data([0]) + Data(user.utf8) + Data([0]) + Data(password.utf8)
            case .xoauth2(let user, let token):
                data = Data("user=\(user)".utf8) + Data([1]) + Data("auth=Bearer \(token)".utf8) + Data([1]) + Data([1])
            }
            return InitialResponse(ByteBuffer(bytes: data))
        }
    }

    /// The client response that answers a server challenge, so that the server can finish the exchange.
    ///
    /// None of these mechanisms has a real challenge step: the whole credential travels in ``initialResponse``, and
    /// a server that accepts it replies with a tagged `OK` straight away. A challenge therefore only ever means
    /// "that credential was rejected, and here is why" (see ``AuthenticationFailure``). The server then waits,
    /// because in SASL every challenge must be answered before the exchange can end. Until the client sends this
    /// response the tagged `NO` never arrives, and the command sits there until it times out.
    ///
    /// What to send is fixed by each mechanism:
    ///
    /// - `OAUTHBEARER`: a single `0x01` byte, `AQ==` once base64-encoded.
    ///   [RFC 7628, section 3.2.3](https://www.rfc-editor.org/rfc/rfc7628#section-3.2.3): "The client MUST then
    ///   send either an additional client response consisting of a single %x01 (control A) character to the server
    ///   in order to allow the server to finish the exchange or a SASL abort message".
    /// - `XOAUTH2`: nothing, which goes out as an empty line. Google's
    ///   [XOAUTH2 protocol](https://developers.google.com/workspace/gmail/imap/xoauth2-protocol): "The client sends
    ///   an empty response ("\r\n") to the challenge containing the error message."
    /// - `PLAIN`: nothing. [RFC 4616](https://www.rfc-editor.org/rfc/rfc4616) defines no server challenge, so this
    ///   is never expected to be used. It exists so that a misbehaving server still gets an answer; an empty
    ///   response carries no credential, so the server can only reject it.
    ///
    /// - Note: The other way to end the exchange is to cancel it with a line holding a single `*`
    ///   ([RFC 3501, section 6.2.2](https://www.rfc-editor.org/rfc/rfc3501#section-6.2.2)). That isn't used here
    ///   because NIOIMAP base64-encodes every continuation response, so a literal `*` can't be sent through it.
    var challengeResponse: ByteBuffer {
        switch self {
        case .oauthbearer: ByteBuffer(bytes: [1])
        case .plain, .xoauth2: ByteBuffer()
        }
    }

    // MARK: CustomStringConvertible
    public var description: String {
        "\(mechanism) \"\(user)\""
    }
}

/// Extends `String` with the encoding ``Authentication`` applies to a user name before sending it to a server.
private extension String {
    /// The string as a `saslname`: the form a user name must take inside the GS2 header of an `OAUTHBEARER` response.
    ///
    /// `OAUTHBEARER` starts its response with a GS2 header, `n,a=<user>,`
    /// ([RFC 7628, section 3.1](https://www.rfc-editor.org/rfc/rfc7628#section-3.1)). The header is a comma-separated
    /// list and `=` introduces an escape, so neither character can appear in the user name as itself.
    /// [RFC 5801, section 4](https://www.rfc-editor.org/rfc/rfc5801#section-4) defines what can:
    ///
    /// ```
    /// UTF8-1-safe    = %x01-2B / %x2D-3C / %x3E-7F
    ///                  ;; As UTF8-1 in RFC 3629 except
    ///                  ;; NUL, "=", and ",".
    /// saslname       = 1*(UTF8-char-safe / "=2C" / "=3D")
    /// gs2-authzid    = "a=" saslname
    /// ```
    ///
    /// So `,` is sent as `=2C` and `=` as `=3D`, after their hexadecimal character codes.
    /// [RFC 5802, section 5.1](https://www.rfc-editor.org/rfc/rfc5802#section-5.1), which uses the same rule, puts it
    /// plainly: "The characters ',' or '=' in usernames are sent as '=2C' and '=3D' respectively."
    ///
    /// This is not a formality. `=` is legal in the local part of an email address (`user=tag@example.com`), and a
    /// server that parses the header strictly rejects a user name that contains it unescaped, or reads a user name
    /// with an unescaped `,` as ending at the comma.
    ///
    /// Each character is replaced once, in a single pass. Two passes would have to run in the right order:
    /// replacing `,` first leaves an `=` behind for the second pass to escape again, turning `,` into `=3D2C`.
    ///
    /// - Note: Only `OAUTHBEARER` needs this. `XOAUTH2` and `PLAIN` separate their fields with control characters
    ///   and define no escaping.
    var saslName: String {
        reduce(into: "") { saslName, character in
            switch character {
            case ",": saslName += "=2C"
            case "=": saslName += "=3D"
            default: saslName.append(character)
            }
        }
    }
}

extension AuthenticationMechanism: @retroactive CustomStringConvertible {
    /// OAuth 2.0 bearer tokens,  `OAUTHBEARER`, described in [RFC 7628](https://www.rfc-editor.org/info/rfc7628)
    public static let oauthBearer: Self = Self("OAUTHBEARER")!

    /// Google-proprietary [OAuth 2.0 mechanism ](https://developers.google.com/workspace/gmail/imap/xoauth2-protocol)
    public static let xoauth2: Self = Self("XOAUTH2")!

    // MARK: CustomStringConvertible
    public var description: String { String(self) }
}

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
                data = Data("n,a=\(user),".utf8) + Data([1]) + Data("auth=Bearer \(token)".utf8) + Data([1]) + Data([1])
            case .plain(let user, let password):
                data = Data([0]) + Data(user.utf8) + Data([0]) + Data(password.utf8)
            case .xoauth2(let user, let token):
                data = Data("user=\(user)".utf8) + Data([1]) + Data("auth=Bearer \(token)".utf8) + Data([1]) + Data([1])
            }
            return InitialResponse(ByteBuffer(bytes: data))
        }
    }

    // MARK: CustomStringConvertible
    public var description: String {
        "\(mechanism) \"\(user)\""
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

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import NIOCore
import NIOIMAPCore

public enum Authentication: CustomStringConvertible, Equatable, Sendable {
    public typealias Mechanism = AuthenticationMechanism

    case plain(_ user: String, password: String)
    case xoauth2(_ user: String, token: String)

    public var mechanism: Mechanism {
        switch self {
        case .plain: .plain
        case .xoauth2: .xOAuth2
        }
    }

    public var user: String {
        switch self {
        case .plain(let user, _), .xoauth2(let user, _): user
        }
    }

    var initialResponse: InitialResponse {
        get throws {
            switch self {
            case .plain(let user, let password):
                let data: Data = Data([0]) + Data(user.utf8) + Data([0]) + Data(password.utf8)
                return InitialResponse(ByteBuffer(bytes: data))
            case .xoauth2:
                fatalError("Authentication.initialResponse not implemented for case xoauth2")
            }
        }
    }

    // MARK: CustomStringConvertible
    public var description: String {
        "\(mechanism) \"\(user)\""
    }
}

extension AuthenticationMechanism: @retroactive CustomStringConvertible {
    public static let xOAuth2: Self = Self("XOAUTH2")!

    // MARK: CustomStringConvertible
    public var description: String { String(self) }
}

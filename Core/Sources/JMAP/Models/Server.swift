// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// ``JMAPClient`` requests ``Session`` from `Server`.
public struct Server: CustomStringConvertible, Equatable, Sendable {
    public let authorization: Authorization?
    public let host: String
    public let port: Int

    public init(
        authorization: Authorization?,
        host: String,
        port: Int = 443
    ) {
        self.authorization = authorization
        self.host = host
        self.port = port
    }

    // MARK: CustomStringConvertible
    public var description: String { "\(host):\(port)" }
}

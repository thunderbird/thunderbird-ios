// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Errors describing impossible or ineligible``Method`` operation, part of [JMAP core](https://jmap.io/spec/rfc8620/#section-3.6)
public enum MethodError: String, CaseIterable, CustomStringConvertible, Decodable, Error, Identifiable {
    case accountNotFound, accountNotSupportedByMethod, accountReadOnly
    case forbidden
    case invalidArguments, invalidResultReference
    case serverFail, serverPartialFail, serverUnavailable
    case unknownMethod

    // MARK: CustomStringConvertible
    public var description: String {
        switch self {
        case .accountNotFound: "Account not found"
        case .accountNotSupportedByMethod: "Account not supported by method"
        case .accountReadOnly: "Account read only"
        case .forbidden: "Forbidden"
        case .invalidArguments: "Invalid arguments"
        case .invalidResultReference: "Invalid result reference"
        case .serverFail, .serverPartialFail: "Server fail"
        case .serverUnavailable: "Sever unavailable"
        case .unknownMethod: "Unknown method"
        }
    }

    // MARK: Decodable
    public init(from decoder: any Decoder) throws {
        var container: UnkeyedDecodingContainer = try decoder.unkeyedContainer()
        let _: String = try container.decode(String.self)  // Skip iterable container pointer to next index
        let dictionary: [String: String] = try container.decode([String: String].self)
        guard let error: Self = Self(rawValue: dictionary["type"] ?? "") else {
            throw URLError(.cannotDecodeRawData)
        }
        self = error
    }

    // MARK: Identifiable
    public var id: String { rawValue }
}

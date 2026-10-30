// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Request-level configuration errors, part of [JMAP core](https://jmap.io/spec/rfc8620/#section-3.6)
public struct RequestError: Error, Decodable, CustomStringConvertible {

    /// Enumerated error code derived from `type` raw value
    public enum Code: String, CaseIterable, Codable, CustomStringConvertible, Identifiable, Sendable {
        case limit = "urn:ietf:params:jmap:error:limit"
        case notJSON = "urn:ietf:params:jmap:error:notJSON"
        case notRequest = "urn:ietf:params:jmap:error:notRequest"
        case unknownCapability = "urn:ietf:params:jmap:error:unknownCapability"

        // MARK: CustomStringConvertible
        public var description: String {
            switch self {
            case .limit: "Limit"
            case .notJSON: "Not JSON"
            case .notRequest: "Not request"
            case .unknownCapability: "Unknown capability"
            }
        }

        // MARK: Identifiable
        public var id: String { rawValue }
    }

    public let code: Code
    public let detail: String

    init(_ code: Code, detail: String = "") {
        self.code = code
        self.detail = detail
    }

    // MARK: Decodable
    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<Key> = try decoder.container(keyedBy: Key.self)
        code = try container.decode(Code.self, forKey: .type)
        detail = try container.decode(String.self, forKey: .detail)
    }

    private enum Key: CodingKey {
        case `type`, detail
    }

    // MARK: CustomStringConvertible
    public var description: String { "\(code)\(detail.isEmpty ? "" : "; \(detail)")" }
}

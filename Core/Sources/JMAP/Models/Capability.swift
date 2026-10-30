// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Capabilities are a component of the JMAP ``Session`` object, part of [JMAP core.](https://jmap.io/spec/rfc8620/#section-2)
public struct Capability: Decodable, Sendable {
    public enum Key: String, CaseIterable, Codable, CustomStringConvertible, Identifiable, Sendable {
        case calendars = "urn:ietf:params:jmap:calendars"
        case contacts = "urn:ietf:params:jmap:contacts"
        case core = "urn:ietf:params:jmap:core"
        case mail = "urn:ietf:params:jmap:mail"
        case submission = "urn:ietf:params:jmap:submission"

        // MARK: CustomStringConvertible
        public var description: String { rawValue.components(separatedBy: ":").last! }

        // MARK: Identifiable
        public var id: String { rawValue }
    }

    public enum SortOption: String, CaseIterable, Codable, CustomStringConvertible, Identifiable, Sendable {
        case received = "receivedAt"
        case from, to, subject, size
        case spamScore = "header.x-spam-score"

        // MARK: CustomStringConvertible
        public var description: String { rawValue }

        // MARK: Identifiable
        public var id: String { rawValue }
    }

    // MARK: Core
    public let maxSizeUpload: Int?
    public let maxConcurrentUpload: Int?
    public let maxSizeRequest: Int?
    public let maxConcurrentRequests: Int?
    public let maxCallsInRequest: Int?
    public let maxObjectsInGet: Int?
    public let maxObjectsInSet: Int?
    public let collationAlgorithms: [String]?

    // MARK: Mail
    public let maxSizeMailboxName: Int?
    public let maxMailboxDepth: Int?
    public let maxMailboxesPerEmail: Int?
    public let maxSizeAttachmentsPerEmail: Int?
    public let mayCreateTopLevelMailbox: Bool?
    public let emailQuerySortOptions: [SortOption]?

    // MARK: Submission
    public let maxDelayedSend: Int?
}

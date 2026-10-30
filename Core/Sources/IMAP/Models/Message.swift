// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MIME
import NIOIMAPCore

public typealias MessageSet = [SequenceNumber: Message]

public struct Message: Sendable {
    public fileprivate(set) var body: Body?
    public fileprivate(set) var emailID: String?
    public fileprivate(set) var envelope: Envelope
    public fileprivate(set) var flags: Set<Flag>
    public fileprivate(set) var gmailLabels: Set<GmailLabel>
    public fileprivate(set) var gmailMessageID: UInt64?
    public fileprivate(set) var gmailThreadID: UInt64?
    public fileprivate(set) var internalDate: Date?
    public fileprivate(set) var threadID: String?
    public fileprivate(set) var uid: UID?

    public init(
        body: Body? = nil,
        emailID: String? = nil,
        envelope: Envelope = Envelope(),
        flags: [Flag] = [],
        gmailLabels: [GmailLabel] = [],
        gmailMessageID: UInt64? = nil,
        gmailThreadID: UInt64? = nil,
        internalDate: Date? = nil,
        threadID: String? = nil,
        uid: UID? = nil
    ) {
        self.body = body
        self.emailID = emailID
        self.envelope = envelope
        self.flags = Set(flags)
        self.gmailLabels = Set(gmailLabels)
        self.gmailMessageID = gmailMessageID
        self.gmailThreadID = gmailThreadID
        self.internalDate = internalDate
        self.threadID = threadID
        self.uid = uid
    }
}

extension Message {
    public enum Component: CustomStringConvertible, Equatable, Identifiable, Sendable {
        case bodyPart(SectionSpecifier, Data)
        case bodyStructure(BodyStructure, _ hasExtensionData: Bool = false)
        case emailID(String)
        case envelope(Envelope)
        case flags(Set<Flag>)
        case gmailLabels(Set<GmailLabel>)
        case gmailMessageID(UInt64)
        case gmailThreadID(UInt64)
        case internalDate(Date)
        case threadID(String)
        case uid(UID)

        // Shared convenience decoder/mapper for message components
        // Used by `FetchHandler`, `IdleHandler` and `NoopHandler`
        init?(_ attribute: MessageAttribute) {
            switch attribute {
            case .body(let structure, let hasExtensionData):
                switch structure {
                case .valid(let structure):
                    self = .bodyStructure(structure, hasExtensionData)
                case .invalid:
                    return nil
                }
            case .emailID(let emailID):
                self = .emailID(String(emailID))
            case .envelope(let envelope):
                self = .envelope(Envelope(envelope))
            case .flags(let flags):
                self = .flags(Set(flags))
            case .gmailLabels(let labels):
                self = .gmailLabels(Set(labels))
            case .gmailMessageID(let id):
                self = .gmailMessageID(id)
            case .gmailThreadID(let id):
                self = .gmailThreadID(id)
            case .internalDate(let serverMessageDate):
                guard let date: Date = try? Date(serverMessageDate: serverMessageDate) else {
                    return nil
                }
                self = .internalDate(date)
            case .threadID(let threadID):
                guard let threadID: String = String(threadID: threadID) else {
                    return nil
                }
                self = .threadID(threadID)
            case .uid(let uid):
                self = .uid(uid)
            default:
                return nil
            }
        }

        // MARK: CustomStringConvertible
        public var description: String {
            switch self {
            case .bodyPart(_, let data): "\(id) (\(data))"
            case .bodyStructure(let structure, let hasExtensionsData): "\(id): \(structure)\(hasExtensionsData ? " (hasExtensionsData)" : "")"
            case .emailID(let id), .threadID(let id): "\(self.id): \(id)"
            case .envelope(let envelope): "\(id): \(envelope)"
            case .flags(let flags): "\(id): \(flags)"
            case .gmailLabels(let labels): "\(id): \(labels)"
            case .gmailMessageID(let id), .gmailThreadID(let id): "\(self.id): \(id)"
            case .internalDate(let date): "\(id): \(date)"
            case .uid(let uid): "\(id): \(uid)"
            }
        }

        // MARK: Equatable
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }

        // MARK: Identifiable
        public var id: String {
            switch self {
            case .bodyPart(let section, _): "bodyPart: \(section)"
            case .bodyStructure: "bodyStructure"
            case .emailID: "emailID"
            case .envelope: "envelope"
            case .flags: "flags"
            case .gmailLabels: "gmailLabels"
            case .gmailMessageID: "gmailMessageID"
            case .gmailThreadID: "gmailThreadID"
            case .internalDate: "internalDate"
            case .threadID: "threadID"
            case .uid: "uid"
            }
        }
    }

    func merging(_ components: [Component]) -> Self {
        var message: Self = self
        for component in components {
            switch component {
            case .bodyPart(_, let data):
                message.body = try? Body(data)
            case .bodyStructure:
                break  // Only decode complete message body
            case .emailID(let emailID):
                message.emailID = emailID
            case .envelope(let envelope):
                message.envelope = envelope
            case .flags(let flags):
                message.flags = flags
            case .gmailLabels(let gmailLabels):
                message.gmailLabels = gmailLabels
            case .gmailMessageID(let gmailMessageID):
                message.gmailMessageID = gmailMessageID
            case .gmailThreadID(let gmailThreadID):
                message.gmailThreadID = gmailThreadID
            case .internalDate(let internalDate):
                message.internalDate = internalDate
            case .threadID(let threadID):
                message.threadID = threadID
            case .uid(let uid):
                message.uid = uid
            }
        }
        return message
    }

    init(_ components: [Component]) {
        self = Self().merging(components)
    }
}

extension MessageSet {

    /// Array of ``Message`` ordered by ascending ``SequenceNumber``
    public var messages: [Message] {
        var messages: [Message] = []
        for key in keys.sorted() {
            messages.append(self[key]!)
        }
        return messages
    }
}

private extension String {
    init?(threadID: ThreadID?) {
        guard let threadID else {
            return nil
        }
        self = Self(threadID)
    }
}

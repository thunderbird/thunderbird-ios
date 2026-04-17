import NIOCore
import NIOIMAPCore

/// Server capability
public struct Capability: CustomStringConvertible, Equatable, Hashable, RawRepresentable, Sendable {
    public static var condStore: Self { Capability(.condStore) }
    public static var idle: Self { Capability(.idle) }
    public static var gmailExtensions: Self { Capability(.gmailExtensions) }
    public static var mailboxSpecificAppendLimit: Self { Capability(.mailboxSpecificAppendLimit) }
    public static var objectID: Self { Capability(.objectID) }
    public static var preview: Self { Capability(.preview) }
    public static var uidPlus: Self { Capability(.uidPlus) }

    public enum Status: String, CustomStringConvertible, Sendable {
        case size = "SIZE"

        // MARK: CustomStringConvertible
        public var description: String { rawValue }
    }

    public static func status(_ status: Status) -> Self {
        Capability(.status(NIOIMAPCore.Capability.StatusKind(status.rawValue)))
    }

    public var label: String { components[0] }

    public var value: String? {
        components.count == 2 ? components[1] : nil
    }

    init(_ capability: NIOIMAPCore.Capability) {
        self.init(rawValue: capability.rawValue)!
    }

    private var components: [String] { rawValue.components(separatedBy: "=") }

    // MARK: CustomStringConvertible
    public var description: String { rawValue }

    // MARK: RawRepresentable
    public let rawValue: String

    public init?(rawValue: String) {
        guard !rawValue.isEmpty else {
            return nil
        }
        self.rawValue = rawValue
    }
}

private extension NIOIMAPCore.Capability {
    var rawValue: String { (value ?? "").isEmpty ? "\(name)" : "\(name)=\(value!)" }
}

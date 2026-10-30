// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore
import NIOIMAPCore

/// One feature token advertised by an IMAP server in a `CAPABILITY` response.
///
/// For example, `* CAPABILITY IMAP4rev1 IDLE AUTH=PLAIN` advertises three tokens.
/// Each instance stores one token, such as `IDLE` or `AUTH=PLAIN`, so the client
/// can check which commands, extensions, and authentication mechanisms it may use.
/// These describe server features, rather than containing email or mailbox data.
public struct Capability: CustomStringConvertible, Equatable, Hashable, RawRepresentable, Sendable {
    /// `CONDSTORE`: tracks message changes with modification sequences and supports conditional flag updates.
    public static var condStore: Self { Capability(.condStore) }
    /// `IDLE`: lets the server notify the client of mailbox changes while the connection waits.
    public static var idle: Self { Capability(.idle) }
    /// `X-GM-EXT-1`: exposes Gmail labels, message IDs, thread IDs, and Gmail search extensions.
    public static var gmailExtensions: Self { Capability(.gmailExtensions) }
    /// `APPENDLIMIT`: supports discovering per-mailbox limits on the size of messages that can be appended.
    public static var mailboxSpecificAppendLimit: Self { Capability(.mailboxSpecificAppendLimit) }
    /// `OBJECTID`: provides stable identifiers for mailboxes, emails, and threads.
    public static var objectID: Self { Capability(.objectID) }
    /// `PREVIEW`: lets the client fetch a short, server-generated preview of a message body.
    public static var preview: Self { Capability(.preview) }
    /// `SASL-IR`: allows the initial SASL authentication response in the `AUTHENTICATE` command.
    public static var saslIR: Self { Capability(.saslIR) }
    /// `UIDPLUS`: reports UIDs assigned by APPEND/COPY and supports expunging specific UIDs.
    public static var uidPlus: Self { Capability(.uidPlus) }

    /// Additional mailbox status information advertised through a `STATUS=...` capability.
    public enum Status: String, CustomStringConvertible, Sendable {
        /// `STATUS=SIZE`: supports requesting the mailbox's total message size in bytes.
        case size = "SIZE"

        // MARK: CustomStringConvertible
        public var description: String { rawValue }
    }

    /// Creates a status capability token, for example `STATUS=SIZE`.
    public static func status(_ status: Status) -> Self {
        Capability(.status(NIOIMAPCore.Capability.StatusKind(status.rawValue)))
    }

    /// Creates a supported authentication token, for example `AUTH=PLAIN`.
    public static func authenticate(_ mechanism: Authentication.Mechanism) -> Self {
        Capability(.authenticate(mechanism))
    }

    /// The token name before `=`, such as `AUTH`; a bare token like `IDLE` is its own label.
    public var label: String { components[0] }

    /// The parameter after `=`, such as `PLAIN` in `AUTH=PLAIN`; `nil` for bare tokens like `IDLE`.
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
    /// The complete capability token as received from the server, such as `AUTH=PLAIN`.
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

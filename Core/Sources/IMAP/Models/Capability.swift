// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore
import NIOIMAPCore

/// Capability represents one feature token advertised by an IMAP server in a
/// CAPABILITY response. For example, "* CAPABILITY IMAP4rev1 IDLE AUTH=PLAIN"
/// advertises three tokens:
/// - IMAP4rev1: the server supports revision 1 of the IMAP4 protocol, which defines
///   the baseline commands for accessing and managing mailboxes and messages.
/// - IDLE: the server supports waiting for mailbox change notifications over an
///   open connection, so the client does not have to keep polling for changes.
/// - AUTH=PLAIN: the server supports the PLAIN SASL authentication mechanism,
///   which sends credentials without encrypting them itself; TLS protects them
///   in transit. This advertises an available login method, not an actual password.
///
/// The leading "* CAPABILITY" identifies an untagged capability response;
/// it is response syntax, not one of the advertised feature tokens.
///
/// Each instance stores one token, such as "IDLE" or "AUTH=PLAIN", so the client
/// can check which commands, extensions, and authentication mechanisms it may use.
/// These describe server features, rather than containing email or mailbox data.

public struct Capability: CustomStringConvertible, Equatable, Hashable, RawRepresentable, Sendable {
    /// `CONDSTORE` (Conditional STORE): helps clients synchronize message flags
    /// such as read/unread and starred, and detect conflicting updates.
    ///
    /// The server assigns each message a modification sequence (`MODSEQ`): an
    /// increasing number that changes when its metadata, such as flags, changes.
    /// This is a version marker, not a message ID or timestamp. A client can save
    /// its sync position and use `CHANGEDSINCE` to fetch subsequent flag changes
    /// instead of fetching the flags of every message again.
    ///
    /// For updates, `UNCHANGEDSINCE` means "apply this flag change only if the
    /// message has not changed since this version." For example, if this client
    /// last saw MODSEQ 42 but another client changes the flags to MODSEQ 43,
    /// an update conditioned on 42 is skipped and reported as `MODIFIED`.
    /// The client can then fetch the current flags and reconcile the conflict.
    ///
    /// See [RFC 7162, section 3.1](https://www.rfc-editor.org/rfc/rfc7162.html#section-3.1).
    public static var condStore: Self { Capability(.condStore) }

    /// `IDLE`: lets the server notify the client of mailbox changes while the connection waits.
    public static var idle: Self { Capability(.idle) }

    /// `X-GM-EXT-1`: exposes Gmail labels, message IDs, thread IDs, and Gmail search extensions.
    public static var gmailExtensions: Self { Capability(.gmailExtensions) }

    /// `APPENDLIMIT`: supports discovering per-mailbox limits on the size of messages that can be appended.
    public static var mailboxSpecificAppendLimit: Self { Capability(.mailboxSpecificAppendLimit) }

    /// `OBJECTID`: the standardized IMAP object identifier extension (RFC 8474).
    /// Servers advertise this token in their `CAPABILITY` response to indicate
    /// support for the following server-assigned identifiers:
    ///
    /// - `MAILBOXID`: identifies a mailbox even when it is renamed.
    /// - `EMAILID`: identifies a message independently of its mailbox-specific
    ///   UID, helping clients recognize the same message across mailboxes.
    /// - `THREADID`: groups related messages into a thread. A server without
    ///   threading support returns `NIL` for this value.
    ///
    /// These identifiers help clients reuse cached data when mailboxes are
    /// renamed or messages change location. This property represents support
    /// for the extension; it does not contain an individual object's identifier.
    ///
    /// See [RFC 8474](https://www.rfc-editor.org/rfc/rfc8474.html).
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

// Example IMAP capability data (illustrative server responses)
//
// C: is data sent by the client; S: is data received from the server. These
// prefixes explain the direction and are not part of the actual IMAP data.
// Each response below belongs to a separate example connection.
//
// 1. Basic protocol and authentication support
// C: A001 CAPABILITY
// S: * CAPABILITY IMAP4rev1 AUTH=PLAIN
// S: A001 OK CAPABILITY completed
//
// IMAP4rev1 advertises the baseline protocol. AUTH=PLAIN advertises an available
// login mechanism; it does not contain credentials. PLAIN does not encrypt
// credentials itself, so TLS must protect them in transit. The line beginning
// with "*" carries the capability list. A001 matches the client's command tag;
// the final OK line confirms that the command succeeded.
//
// 2. Mailbox notifications and efficient flag synchronization
// C: A002 CAPABILITY
// S: * CAPABILITY IMAP4rev1 IDLE CONDSTORE UIDPLUS
// S: A002 OK CAPABILITY completed
//
// IDLE allows mailbox change notifications. CONDSTORE supports fetching flag
// changes since a saved version and detecting conflicting flag updates.
// UIDPLUS reports assigned UIDs for APPEND/COPY and allows targeted expunges.
// These tokens advertise features; this response contains no actual messages.
//
// 3. Stable identifiers, message previews, and mailbox size reporting
// C: A003 CAPABILITY
// S: * CAPABILITY IMAP4rev1 OBJECTID PREVIEW STATUS=SIZE APPENDLIMIT=52428800
// S: A003 OK CAPABILITY completed
//
// OBJECTID supports MAILBOXID, EMAILID, and THREADID (which can be NIL).
// PREVIEW supports fetching short message previews. STATUS=SIZE supports
// requesting the total message size of a mailbox. APPENDLIMIT=52428800
// advertises a maximum appended message size of 52,428,800 bytes (50 MiB).
// The identifiers, previews, and mailbox sizes must be requested separately.
//
// 4. Gmail-specific features and an authentication optimization
// C: A004 CAPABILITY
// S: * CAPABILITY IMAP4rev1 X-GM-EXT-1 AUTH=PLAIN SASL-IR
// S: A004 OK CAPABILITY completed
//
// X-GM-EXT-1 advertises Gmail-specific labels, message/thread IDs, and search.
// SASL-IR allows sending the first authentication response in the AUTHENTICATE
// command itself, avoiding an extra exchange before sending that response.
// This is a shortened example, not a complete Gmail capability list.
//
// How individual tokens map to this type:
// rawValue "IDLE"                 -> label "IDLE",        value nil
// rawValue "AUTH=PLAIN"           -> label "AUTH",        value "PLAIN"
// rawValue "STATUS=SIZE"          -> label "STATUS",      value "SIZE"
// rawValue "APPENDLIMIT=52428800"  -> label "APPENDLIMIT", value "52428800"
// Each token becomes a separate Capability; the entire response line does not.

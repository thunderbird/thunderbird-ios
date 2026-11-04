// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Updates to selected ``Mailbox`` during ``IMAPClient`` idle
public enum IdleEvent: Sendable {

    /// IMAP ``Server`` disconnected during idle
    case bye(String?)

    ///  ``Message`` deleted from selected ``Mailbox`` during idle
    case expunge(SequenceNumber)

    /// Fetched updates to a specific ``Message``,  collected as ``Message.Component``
    case fetch(SequenceNumber, [Message.Component])

    /// Message count changed for selected ``Mailbox``
    case status(Mailbox.Status)
}

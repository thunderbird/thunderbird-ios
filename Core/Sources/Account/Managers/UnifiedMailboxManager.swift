// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Manages mailbox managers for all user accounts, providing unified access to mailboxes.
@Observable
public final class UnifiedMailboxManager {
    /// A collection of MailboxManager instances for each account.
    public var mailboxManagers: [MailboxManager] = []

    /// Initializes an empty unified mailbox manager.
    public init() {}
}

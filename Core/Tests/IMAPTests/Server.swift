// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import IMAP
import Testing

extension Server: CaseIterable {

    // MARK: AOL
    static var aol: Self {
        Server(
            .ssl,
            authentication: nil,
            hostname: "imap.aol.com",
            port: 993
        )
    }

    // MARK: Gmail
    static var gmail: Self {
        Server(
            .ssl,
            authentication: nil,
            hostname: "imap.gmail.com",
            port: 993
        )
    }

    // MARK: iCloud
    static var icloud: Self {
        Server(
            .ssl,
            authentication: nil,
            hostname: "imap.mail.me.com",
            port: 993
        )
    }

    // MARK: Outlook
    static var outlook: Self {
        Server(
            .ssl,
            authentication: nil,
            hostname: "outlook.office365.com",
            port: 993
        )
    }

    var isDisabled: Bool { authentication == nil }

    static func allCases(disabled: Bool) -> [Self] {
        allCases.filter { $0.isDisabled == disabled }
    }

    // MARK: CaseIterable
    public static let allCases: [Self] = [.aol, .gmail, .icloud, .outlook]
}

// Catch when test account usernames or passwords are leaking
@Test(arguments: Server.allCases) func isDisabled(_ server: Server) {
    #expect(server.authentication == nil)
}

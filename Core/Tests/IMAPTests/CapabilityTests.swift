// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import IMAP
import Testing

struct CapabilityTests {
    @Test func capabilityInit() {
        #expect(Capability.condStore.rawValue == "CONDSTORE")
        #expect(Capability.idle.rawValue == "IDLE")
        #expect(Capability.gmailExtensions.rawValue == "X-GM-EXT-1")
        #expect(Capability.mailboxSpecificAppendLimit.rawValue == "APPENDLIMIT")
        #expect(Capability.objectID.rawValue == "OBJECTID")
        #expect(Capability.preview.rawValue == "PREVIEW")
        #expect(Capability.uidPlus.rawValue == "UIDPLUS")
        #expect(Capability.status(.size).rawValue == "STATUS=SIZE")
    }

    //Expect: Use the name the server advertises the capability under.
    //Case: When the capability is one that `LIST` return options depend on.
    @Test(arguments: [
        (Capability.listExtended, "LIST-EXTENDED"),
        (Capability.listStatus, "LIST-STATUS")
    ])
    func rawValue_matchesAdvertisedName_whenCapabilityGatesListReturnOptions(input: Capability, expected: String) {
        // Act
        let actual = input.rawValue

        // Assert
        #expect(actual == expected)
    }
}

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
}

import Testing
import Foundation
@testable import Account

struct URLProtectionSpaceTests {
    @Test func account() {
        #expect(URLProtectionSpace.account.host == "thunderbird.net")
    }
}

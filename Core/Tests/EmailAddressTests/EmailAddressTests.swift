@testable import EmailAddress
import Foundation
import Testing

struct EmailAddressTests {
    @Test func host() {
        #expect(EmailAddress("user@example.com").host == "example.com")
        #expect(EmailAddress("h@x0r@192.168.1.1").host == "192.168.1.1")
        #expect(EmailAddress("abc@").host == nil)
        #expect(EmailAddress(" ").host == nil)
    }

    @Test func local() {
        #expect(EmailAddress("user@example.com").local == "user")
        #expect(EmailAddress("h@x0r@192.168.1.1").local == "h@x0r")
        #expect(EmailAddress("abc@").local == "abc")
        #expect(EmailAddress("example.com").local == nil)
        #expect(EmailAddress(" ").local == nil)
    }

    @Test func isEmailAddress() {
        #expect(EmailAddress("user@example.com").isEmailAddress == true)
        #expect(EmailAddress("h@x0r@192.168.1.1").isEmailAddress == true)
        #expect(EmailAddress("abc@").isEmailAddress == false)
        #expect(EmailAddress("example.com").isEmailAddress == false)
        #expect(EmailAddress(" ").isEmailAddress == false)
    }

    @Test func valueInit() {
        #expect(EmailAddress("name@example.com", label: "Example Name").value == "name@example.com")
        #expect(EmailAddress("name@example.com", label: "Example Name").label == "Example Name")
        #expect(EmailAddress("name@example.com", label: "").label == nil)
        #expect(EmailAddress("name@example.com").label == nil)
    }

    // MARK: Codable
    @Test func encode() throws {
        #expect(try JSONEncoder().encode(EmailAddress("name@example.com", label: "Example Name")) == "\"Example Name <name@example.com>\"".data(using: .utf8))
        #expect(try JSONEncoder().encode(EmailAddress("name@example.com")) == "\"name@example.com\"".data(using: .utf8))
    }

    @Test func decoderInit() throws {
        let data: [Data] = [
            "\"Example Name <name@example.com>\"".data(using: .utf8)!,
            "\"name@example.com\"".data(using: .utf8)!
        ]
        #expect(try JSONDecoder().decode(EmailAddress.self, from: data[0]).value == "name@example.com")
        #expect(try JSONDecoder().decode(EmailAddress.self, from: data[0]).label == "Example Name")
        #expect(try JSONDecoder().decode(EmailAddress.self, from: data[1]).value == "name@example.com")
        #expect(try JSONDecoder().decode(EmailAddress.self, from: data[1]).label == nil)
    }

    // MARK: ExpressibleByStringLiteral
    @Test func stringLiteralInit() {
        let labeledEmailAddress: EmailAddress = "Example Name <name@example.com>"
        #expect(labeledEmailAddress.value == "name@example.com")
        #expect(labeledEmailAddress.label == "Example Name")
        let emailAddress: EmailAddress = "name@example.com"
        #expect(emailAddress.value == "name@example.com")
        #expect(emailAddress.label == nil)
    }

    @Test func description() {
        #expect(EmailAddress("name@example.com", label: "Example Name").description == "Example Name <name@example.com>")
        #expect(EmailAddress("name@example.com").description == "name@example.com")
    }
}

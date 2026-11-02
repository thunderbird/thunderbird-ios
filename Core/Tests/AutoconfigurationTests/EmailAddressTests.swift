// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Autoconfiguration
import Foundation
import Testing

struct EmailAddressTests {
    //Expect: Return the domain after the `@`.
    //Case: When the string is a plain email address.
    @Test func host_returnsDomain_whenStringIsEmailAddress() throws {
        // Arrange
        let input = "user@example.com"
        let expected = "example.com"

        // Act
        let actual = try input.host

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return only the text after the last `@`.
    //Case: When the local part also contains an `@` and the host is an IP address.
    @Test func host_returnsTextAfterLastAt_whenLocalPartContainsAt() throws {
        // Arrange
        let input = "h@x0r@192.168.1.1"
        let expected = "192.168.1.1"

        // Act
        let actual = try input.host

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the string unchanged.
    //Case: When the string is a bare host name with no `@`.
    @Test func host_returnsString_whenStringIsBareHost() throws {
        // Arrange
        let input = "example.com"
        let expected = "example.com"

        // Act
        let actual = try input.host

        // Assert
        #expect(actual == expected)
    }

    //Expect: Throw a `URLError`.
    //Case: When nothing follows the `@`.
    @Test func host_throws_whenNothingFollowsAt() {
        // Arrange
        let input = "abc@"

        // Act & Assert
        #expect(throws: URLError.self) {
            try input.host
        }
    }

    //Expect: Throw a `URLError`.
    //Case: When the string is only whitespace.
    @Test func host_throws_whenStringIsWhitespace() {
        // Arrange
        let input = " "

        // Act & Assert
        #expect(throws: URLError.self) {
            try input.host
        }
    }

    //Expect: Return the text before the `@`.
    //Case: When the string is a plain email address.
    @Test func local_returnsTextBeforeAt_whenStringIsEmailAddress() throws {
        // Arrange
        let input = "user@example.com"
        let expected = "user"

        // Act
        let actual = try input.local

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return everything before the last `@`, including the earlier `@`.
    //Case: When the local part also contains an `@`.
    @Test func local_returnsTextBeforeLastAt_whenLocalPartContainsAt() throws {
        // Arrange
        let input = "h@x0r@192.168.1.1"
        let expected = "h@x0r"

        // Act
        let actual = try input.local

        // Assert
        #expect(actual == expected)
    }

    //Expect: Throw a `URLError`.
    //Case: When the string has no `@`.
    @Test func local_throws_whenStringHasNoAt() {
        // Arrange
        let input = "example.com"

        // Act & Assert
        #expect(throws: URLError.self) {
            try input.local
        }
    }

    //Expect: Build the `_autodiscover._tcp` SRV query name for the address's domain.
    //Case: When the string is a plain email address.
    @Test func query_returnsAutodiscoverQuery_whenStringIsEmailAddress() throws {
        // Arrange
        let input = "user@example.com"
        let expected = "_autodiscover._tcp.example.com"

        // Act
        let actual = try input.query(.autodiscover)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Build the `_imap._tcp` SRV query name using the text after the last `@`.
    //Case: When the local part also contains an `@` and the host is an IP address.
    @Test func query_returnsIMAPQueryForHost_whenLocalPartContainsAt() throws {
        // Arrange
        let input = "h@x0r@192.168.1.1"
        let expected = "_imap._tcp.192.168.1.1"

        // Act
        let actual = try input.query(.imap)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Build the `_smtp._tcp` SRV query name for the host.
    //Case: When the string is a bare host name with no `@`.
    @Test func query_returnsSMTPQuery_whenStringIsBareHost() throws {
        // Arrange
        let input = "example.com"
        let expected = "_smtp._tcp.example.com"

        // Act
        let actual = try input.query(.smtp)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Throw a `URLError`.
    //Case: When nothing follows the `@`.
    @Test func query_throws_whenNothingFollowsAt() {
        // Arrange
        let input = "abc@"

        // Act & Assert
        #expect(throws: URLError.self) {
            try input.query(.jmap)
        }
    }
}

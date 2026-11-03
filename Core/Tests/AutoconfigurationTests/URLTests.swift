// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Autoconfiguration
import Foundation
import Testing

struct URLTests {
    //Expect: Return the provider's `autoconfig` subdomain URL with the address as a query item.
    //Case: When the source is `.provider`.
    @Test func autoconfig_returnsProviderURL_whenSourceIsProvider() throws {
        // Arrange
        let input = "user@example.com"
        let expected = "https://autoconfig.example.com/mail/config-v1.1.xml?emailaddress=user@example.com"

        // Act
        let actual = try URL.autoconfig(input, source: .provider).absoluteString

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the provider's `.well-known` autoconfig URL.
    //Case: When the source is `.wellKnown`.
    @Test func autoconfig_returnsWellKnownURL_whenSourceIsWellKnown() throws {
        // Arrange
        let input = "user@example.com"
        let expected = "https://example.com/.well-known/autoconfig/mail/config-v1.1.xml"

        // Act
        let actual = try URL.autoconfig(input, source: .wellKnown).absoluteString

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the Thunderbird ISPDB URL for the domain.
    //Case: When no source is given, so the default `.ispDB` is used.
    @Test func autoconfig_returnsISPDBURL_whenSourceIsDefault() throws {
        // Arrange
        let input = "user@example.com"
        let expected = "https://autoconfig.thunderbird.net/v1.1/example.com"

        // Act
        let actual = try URL.autoconfig(input).absoluteString

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the `autoconfig` subdomain URL with the address as a query item.
    //Case: When the string is a plain email address.
    @Test func provider_includesEmailAddressQuery_whenStringIsEmailAddress() throws {
        // Arrange
        let input = "user@example.com"
        let expected = "https://autoconfig.example.com/mail/config-v1.1.xml?emailaddress=user@example.com"

        // Act
        let actual = try URL.provider(input).absoluteString

        // Assert
        #expect(actual == expected)
    }

    //Expect: Use the text after the last `@` as the host and the full string as the query item.
    //Case: When the local part also contains an `@` and the host is an IP address.
    @Test func provider_usesTextAfterLastAtAsHost_whenLocalPartContainsAt() throws {
        // Arrange
        let input = "h@x0r@192.168.1.1"
        let expected = "https://autoconfig.192.168.1.1/mail/config-v1.1.xml?emailaddress=h@x0r@192.168.1.1"

        // Act
        let actual = try URL.provider(input).absoluteString

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the `autoconfig` subdomain URL without an `emailaddress` query item.
    //Case: When the string is a bare host name with no `@`.
    @Test func provider_omitsEmailAddressQuery_whenStringIsBareHost() throws {
        // Arrange
        let input = "example.com"
        let expected = "https://autoconfig.example.com/mail/config-v1.1.xml"

        // Act
        let actual = try URL.provider(input).absoluteString

        // Assert
        #expect(actual == expected)
    }

    //Expect: Throw a `URLError`.
    //Case: When the string is only an `@`, so there is no host.
    @Test func provider_throws_whenStringHasNoHost() {
        // Arrange
        let input = "@"

        // Act & Assert
        #expect(throws: URLError.self) {
            try URL.provider(input)
        }
    }

    //Expect: Return the `.well-known` autoconfig URL for the domain.
    //Case: When the string is a plain email address.
    @Test func wellKnown_returnsWellKnownURL_whenStringIsEmailAddress() throws {
        // Arrange
        let input = "user@example.com"
        let expected = "https://example.com/.well-known/autoconfig/mail/config-v1.1.xml"

        // Act
        let actual = try URL.wellKnown(input).absoluteString

        // Assert
        #expect(actual == expected)
    }

    //Expect: Use the text after the last `@` as the host.
    //Case: When the local part also contains an `@` and the host is an IP address.
    @Test func wellKnown_usesTextAfterLastAtAsHost_whenLocalPartContainsAt() throws {
        // Arrange
        let input = "h@x0r@192.168.1.1"
        let expected = "https://192.168.1.1/.well-known/autoconfig/mail/config-v1.1.xml"

        // Act
        let actual = try URL.wellKnown(input).absoluteString

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the `.well-known` autoconfig URL for the host.
    //Case: When the string is a bare host name with no `@`.
    @Test func wellKnown_returnsWellKnownURL_whenStringIsBareHost() throws {
        // Arrange
        let input = "example.com"
        let expected = "https://example.com/.well-known/autoconfig/mail/config-v1.1.xml"

        // Act
        let actual = try URL.wellKnown(input).absoluteString

        // Assert
        #expect(actual == expected)
    }

    //Expect: Throw a `URLError`.
    //Case: When the string is empty.
    @Test func wellKnown_throws_whenStringIsEmpty() {
        // Arrange
        let input = ""

        // Act & Assert
        #expect(throws: URLError.self) {
            try URL.wellKnown(input)
        }
    }

    //Expect: Return the Thunderbird ISPDB URL for the domain.
    //Case: When the string is a plain email address.
    @Test func ispDB_returnsISPDBURL_whenStringIsEmailAddress() throws {
        // Arrange
        let input = "user@example.com"
        let expected = "https://autoconfig.thunderbird.net/v1.1/example.com"

        // Act
        let actual = try URL.ispDB(input).absoluteString

        // Assert
        #expect(actual == expected)
    }

    //Expect: Use the text after the last `@` as the host.
    //Case: When the local part also contains an `@` and the host is an IP address.
    @Test func ispDB_usesTextAfterLastAtAsHost_whenLocalPartContainsAt() throws {
        // Arrange
        let input = "h@x0r@192.168.1.1"
        let expected = "https://autoconfig.thunderbird.net/v1.1/192.168.1.1"

        // Act
        let actual = try URL.ispDB(input).absoluteString

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the Thunderbird ISPDB URL for the host.
    //Case: When the string is a bare host name with no `@`.
    @Test func ispDB_returnsISPDBURL_whenStringIsBareHost() throws {
        // Arrange
        let input = "example.com"
        let expected = "https://autoconfig.thunderbird.net/v1.1/example.com"

        // Act
        let actual = try URL.ispDB(input).absoluteString

        // Assert
        #expect(actual == expected)
    }

    //Expect: Throw a `URLError`.
    //Case: When the string is only whitespace.
    @Test func ispDB_throws_whenStringIsWhitespace() {
        // Arrange
        let input = " "

        // Act & Assert
        #expect(throws: URLError.self) {
            try URL.ispDB(input)
        }
    }

    //Expect: Percent-encode `+` in the `emailaddress` query item, so the provider doesn't decode it as a space.
    //Case: When the email address uses plus addressing.
    //Example: Plus addressing (`name+tag@domain`) is common with Gmail and Fastmail. Sent unencoded, the provider would
    //  look up `user tag@example.com` and could return settings for the wrong user, or none.
    @Test func provider_encodesPlusInEmailAddress_whenAddressUsesPlusAddressing() throws {
        // Arrange
        let input = "user+tag@example.com"
        let expected = "user+tag@example.com"

        // Act
        let actual = try URL.provider(input).query(percentEncoded: true)?.formValue("emailaddress")

        // Assert
        #expect(actual == expected)
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Autoconfiguration
import Foundation
import Testing

struct DomainParserTests {
    //Expect: Return the single-label suffix plus the label before it.
    //Case: When the host has several subdomains and a single-label suffix.
    @Test func init_returnsRegistrableDomain_whenHostHasSingleLabelSuffix() throws {
        // Arrange
        let input = "alt1.smtp.google.com"
        let suffixes: [String] = try SuffixListParser(data: suffixList).suffixList
        let expected = "google.com"

        // Act
        let actual = try DomainParser(host: input, suffixList: suffixes).domain

        // Assert
        #expect(actual == expected)
    }

    //Expect: Keep the full host unchanged.
    //Case: When the host has several subdomains and a single-label suffix.
    @Test func init_preservesHost_whenHostHasSingleLabelSuffix() throws {
        // Arrange
        let input = "alt1.smtp.google.com"
        let suffixes: [String] = try SuffixListParser(data: suffixList).suffixList
        let expected = "alt1.smtp.google.com"

        // Act
        let actual = try DomainParser(host: input, suffixList: suffixes).host

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the matched single-label public suffix.
    //Case: When the host has several subdomains and a single-label suffix.
    @Test func init_returnsMatchedSuffix_whenHostHasSingleLabelSuffix() throws {
        // Arrange
        let input = "alt1.smtp.google.com"
        let suffixes: [String] = try SuffixListParser(data: suffixList).suffixList
        let expected = "com"

        // Act
        let actual = try DomainParser(host: input, suffixList: suffixes).suffix

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the two-label suffix plus the label before it.
    //Case: When the host has one subdomain and a two-label suffix.
    @Test func init_returnsRegistrableDomain_whenHostHasTwoLabelSuffix() throws {
        // Arrange
        let input = "imap.mail-provider.com.au"
        let suffixes: [String] = try SuffixListParser(data: suffixList).suffixList
        let expected = "mail-provider.com.au"

        // Act
        let actual = try DomainParser(host: input, suffixList: suffixes).domain

        // Assert
        #expect(actual == expected)
    }

    //Expect: Keep the full host unchanged.
    //Case: When the host has one subdomain and a two-label suffix.
    @Test func init_preservesHost_whenHostHasTwoLabelSuffix() throws {
        // Arrange
        let input = "imap.mail-provider.com.au"
        let suffixes: [String] = try SuffixListParser(data: suffixList).suffixList
        let expected = "imap.mail-provider.com.au"

        // Act
        let actual = try DomainParser(host: input, suffixList: suffixes).host

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the longer two-label suffix rather than its last label alone.
    //Case: When the host has one subdomain and a two-label suffix.
    @Test func init_returnsMatchedSuffix_whenHostHasTwoLabelSuffix() throws {
        // Arrange
        let input = "imap.mail-provider.com.au"
        let suffixes: [String] = try SuffixListParser(data: suffixList).suffixList
        let expected = "com.au"

        // Act
        let actual = try DomainParser(host: input, suffixList: suffixes).suffix

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the two-label suffix plus only the one label before it.
    //Case: When the host has two subdomains and a two-label suffix.
    @Test func init_returnsRegistrableDomain_whenHostHasSubdomainsAndTwoLabelSuffix() throws {
        // Arrange
        let input = "mail.mx1.example.net.uk"
        let suffixes: [String] = try SuffixListParser(data: suffixList).suffixList
        let expected = "example.net.uk"

        // Act
        let actual = try DomainParser(host: input, suffixList: suffixes).domain

        // Assert
        #expect(actual == expected)
    }

    //Expect: Keep the full host unchanged.
    //Case: When the host has two subdomains and a two-label suffix.
    @Test func init_preservesHost_whenHostHasSubdomainsAndTwoLabelSuffix() throws {
        // Arrange
        let input = "mail.mx1.example.net.uk"
        let suffixes: [String] = try SuffixListParser(data: suffixList).suffixList
        let expected = "mail.mx1.example.net.uk"

        // Act
        let actual = try DomainParser(host: input, suffixList: suffixes).host

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the matched two-label public suffix.
    //Case: When the host has two subdomains and a two-label suffix.
    @Test func init_returnsMatchedSuffix_whenHostHasSubdomainsAndTwoLabelSuffix() throws {
        // Arrange
        let input = "mail.mx1.example.net.uk"
        let suffixes: [String] = try SuffixListParser(data: suffixList).suffixList
        let expected = "net.uk"

        // Act
        let actual = try DomainParser(host: input, suffixList: suffixes).suffix

        // Assert
        #expect(actual == expected)
    }

    //Expect: Throw a `URLError`.
    //Case: When the host doesn't end with any listed public suffix.
    @Test func init_throws_whenHostHasNoListedSuffix() throws {
        // Arrange
        let input = "host.example"
        let suffixes: [String] = try SuffixListParser(data: suffixList).suffixList

        // Act & Assert
        #expect(throws: URLError.self) {
            try DomainParser(host: input, suffixList: suffixes)
        }
    }
}

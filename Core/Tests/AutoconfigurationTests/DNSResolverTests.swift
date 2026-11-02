// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Autoconfiguration
import Testing

struct DNSResolverTests {
    //Expect: Return one record for each of the four services Thundermail publishes.
    //Case: When querying every service for a Thundermail address.
    @Test func querySRV_returnsFourRecords_whenQueryingAllServicesForThundermail() async throws {
        // Arrange
        let input = "username@thundermail.com"
        let expected = 4

        // Act
        let actual = try await DNSResolver.querySRV(input).count

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the IMAP record first, following the order of `Service.allCases`.
    //Case: When querying every service for a Thundermail address.
    @Test func querySRV_returnsIMAPRecordFirst_whenQueryingAllServicesForThundermail() async throws {
        // Arrange
        let input = "username@thundermail.com"
        let expected = "SRVRecord(host=mail.thundermail.com, port=143, weight=1, priority=0)"

        // Act
        let actual = try await DNSResolver.querySRV(input).first?.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the submission record last, following the order of `Service.allCases`.
    //Case: When querying every service for a Thundermail address.
    @Test func querySRV_returnsSubmissionRecordLast_whenQueryingAllServicesForThundermail() async throws {
        // Arrange
        let input = "username@thundermail.com"
        let expected = "SRVRecord(host=mail.thundermail.com, port=587, weight=1, priority=0)"

        // Act
        let actual = try await DNSResolver.querySRV(input).last?.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the Thundermail `imap` record for the address's domain.
    //Case: When querying only the `.imap` service for a Thundermail address.
    @Test func querySRV_returnsIMAPRecord_whenServiceIsIMAPForThundermail() async throws {
        // Arrange
        let input = "username@thundermail.com"
        let expected = "SRVRecord(host=mail.thundermail.com, port=143, weight=1, priority=0)"

        // Act
        let actual = try await DNSResolver.querySRV(input, service: .imap).first?.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the Thundermail `submission` record for the address's domain.
    //Case: When querying only the `.submission` service for a Thundermail address.
    @Test func querySRV_returnsSubmissionRecord_whenServiceIsSubmissionForThundermail() async throws {
        // Arrange
        let input = "username@thundermail.com"
        let expected = "SRVRecord(host=mail.thundermail.com, port=587, weight=1, priority=0)"

        // Act
        let actual = try await DNSResolver.querySRV(input, service: .submission).first?.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the Thundermail `jmap` record for the address's domain.
    //Case: When querying only the `.jmap` service for a Thundermail address.
    @Test func querySRV_returnsJMAPRecord_whenServiceIsJMAPForThundermail() async throws {
        // Arrange
        let input = "username@thundermail.com"
        let expected = "SRVRecord(host=mail.thundermail.com, port=443, weight=1, priority=0)"

        // Act
        let actual = try await DNSResolver.querySRV(input, service: .jmap).first?.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the Fastmail `jmap` record for the address's domain.
    //Case: When querying only the `.jmap` service for a Fastmail address.
    @Test func querySRV_returnsJMAPRecord_whenServiceIsJMAPForFastmail() async throws {
        // Arrange
        let input = "user@fastmail.com"
        let expected = "SRVRecord(host=api.fastmail.com, port=443, weight=1, priority=0)"

        // Act
        let actual = try await DNSResolver.querySRV(input, service: .jmap).first?.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the Gmail `imaps` record for the address's domain.
    //Case: When querying only the `.imaps` service for a Gmail address.
    @Test func querySRV_returnsIMAPSRecord_whenServiceIsIMAPSForGmail() async throws {
        // Arrange
        let input = "user.name@gmail.com"
        let expected = "SRVRecord(host=imap.gmail.com, port=993, weight=0, priority=5)"

        // Act
        let actual = try await DNSResolver.querySRV(input, service: .imaps).first?.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the Gmail `submission` record for the address's domain.
    //Case: When querying only the `.submission` service for a Gmail address.
    @Test func querySRV_returnsSubmissionRecord_whenServiceIsSubmissionForGmail() async throws {
        // Arrange
        let input = "user.name@gmail.com"
        let expected = "SRVRecord(host=smtp.gmail.com, port=587, weight=0, priority=5)"

        // Act
        let actual = try await DNSResolver.querySRV(input, service: .submission).first?.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return at least one MX record.
    //Case: When the address is at Thunderbird's domain.
    @Test func queryMX_returnsRecords_whenAddressIsThunderbird() async throws {
        // Arrange
        let input = "uname@thunderbird.net"

        // Act
        let actual = try await DNSResolver.queryMX(input).count

        // Assert
        #expect(actual > 0)
    }

    //Expect: Return at least one MX record.
    //Case: When the address is at Fastmail's domain.
    @Test func queryMX_returnsRecords_whenAddressIsFastmail() async throws {
        // Arrange
        let input = "user@fastmail.com"

        // Act
        let actual = try await DNSResolver.queryMX(input).count

        // Assert
        #expect(actual > 0)
    }

    //Expect: Return at least one MX record.
    //Case: When the address is at Gmail's domain.
    @Test func queryMX_returnsRecords_whenAddressIsGmail() async throws {
        // Arrange
        let input = "user.name@gmail.com"

        // Act
        let actual = try await DNSResolver.queryMX(input).count

        // Assert
        #expect(actual > 0)
    }
}

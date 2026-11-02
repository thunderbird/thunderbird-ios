// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Autoconfiguration
import Testing

struct SRVResolverTests {
    //Expect: Return the published `jmap` record as the first result.
    //Case: When querying `_jmap._tcp.thundermail.com`, which Thundermail publishes.
    @Test func query_returnsJMAPRecord_whenThundermailPublishesJMAP() async throws {
        // Arrange
        let input = "_jmap._tcp.thundermail.com"
        let expected = "SRVRecord(host=mail.thundermail.com, port=443, weight=1, priority=0)"

        // Act
        let actual = try await SRVResolver().query(input).first?.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the published `imaps` record as the first result.
    //Case: When querying `_imaps._tcp.thundermail.com`, which Thundermail publishes.
    @Test func query_returnsIMAPSRecord_whenThundermailPublishesIMAPS() async throws {
        // Arrange
        let input = "_imaps._tcp.thundermail.com"
        let expected = "SRVRecord(host=mail.thundermail.com, port=993, weight=1, priority=0)"

        // Act
        let actual = try await SRVResolver().query(input).first?.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the published `imap` record as the first result.
    //Case: When querying `_imap._tcp.thundermail.com`, which Thundermail publishes.
    @Test func query_returnsIMAPRecord_whenThundermailPublishesIMAP() async throws {
        // Arrange
        let input = "_imap._tcp.thundermail.com"
        let expected = "SRVRecord(host=mail.thundermail.com, port=143, weight=1, priority=0)"

        // Act
        let actual = try await SRVResolver().query(input).first?.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the published `submissions` record as the first result.
    //Case: When querying `_submissions._tcp.thundermail.com`, which Thundermail publishes.
    @Test func query_returnsSubmissionsRecord_whenThundermailPublishesSubmissions() async throws {
        // Arrange
        let input = "_submissions._tcp.thundermail.com"
        let expected = "SRVRecord(host=mail.thundermail.com, port=465, weight=1, priority=0)"

        // Act
        let actual = try await SRVResolver().query(input).first?.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the published `submission` record as the first result.
    //Case: When querying `_submission._tcp.thundermail.com`, which Thundermail publishes.
    @Test func query_returnsSubmissionRecord_whenThundermailPublishesSubmission() async throws {
        // Arrange
        let input = "_submission._tcp.thundermail.com"
        let expected = "SRVRecord(host=mail.thundermail.com, port=587, weight=1, priority=0)"

        // Act
        let actual = try await SRVResolver().query(input).first?.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return no records.
    //Case: When querying `_autodiscover._tcp.thundermail.com`, which Thundermail doesn't publish.
    @Test func query_returnsEmpty_whenThundermailHasNoAutodiscoverRecord() async throws {
        // Arrange
        let input = "_autodiscover._tcp.thundermail.com"
        let expected: [SRVRecord] = []

        // Act
        let actual = try await SRVResolver().query(input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return no records.
    //Case: When querying `_pop3._tcp.thundermail.com`, which Thundermail doesn't publish.
    @Test func query_returnsEmpty_whenThundermailHasNoPOP3Record() async throws {
        // Arrange
        let input = "_pop3._tcp.thundermail.com"
        let expected: [SRVRecord] = []

        // Act
        let actual = try await SRVResolver().query(input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the published `jmap` record as the first result.
    //Case: When querying `_jmap._tcp.fastmail.com`, which Fastmail publishes.
    @Test func query_returnsJMAPRecord_whenFastmailPublishesJMAP() async throws {
        // Arrange
        let input = "_jmap._tcp.fastmail.com"
        let expected = "SRVRecord(host=api.fastmail.com, port=443, weight=1, priority=0)"

        // Act
        let actual = try await SRVResolver().query(input).first?.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the published `autodiscover` record as the first result.
    //Case: When querying `_autodiscover._tcp.fastmail.com`, which Fastmail publishes.
    @Test func query_returnsAutodiscoverRecord_whenFastmailPublishesAutodiscover() async throws {
        // Arrange
        let input = "_autodiscover._tcp.fastmail.com"
        let expected = "SRVRecord(host=autodiscover.fastmail.com, port=443, weight=1, priority=0)"

        // Act
        let actual = try await SRVResolver().query(input).first?.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the published `imaps` record as the first result.
    //Case: When querying `_imaps._tcp.fastmail.com`, which Fastmail publishes.
    @Test func query_returnsIMAPSRecord_whenFastmailPublishesIMAPS() async throws {
        // Arrange
        let input = "_imaps._tcp.fastmail.com"
        let expected = "SRVRecord(host=imap.fastmail.com, port=993, weight=1, priority=0)"

        // Act
        let actual = try await SRVResolver().query(input).first?.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the published `submissions` record as the first result.
    //Case: When querying `_submissions._tcp.fastmail.com`, which Fastmail publishes.
    @Test func query_returnsSubmissionsRecord_whenFastmailPublishesSubmissions() async throws {
        // Arrange
        let input = "_submissions._tcp.fastmail.com"
        let expected = "SRVRecord(host=smtp.fastmail.com, port=465, weight=1, priority=0)"

        // Act
        let actual = try await SRVResolver().query(input).first?.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return no records.
    //Case: When querying `_pop3._tcp.fastmail.com`, which Fastmail doesn't publish.
    @Test func query_returnsEmpty_whenFastmailHasNoPOP3Record() async throws {
        // Arrange
        let input = "_pop3._tcp.fastmail.com"
        let expected: [SRVRecord] = []

        // Act
        let actual = try await SRVResolver().query(input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return no records.
    //Case: When querying `_submission._tcp.fastmail.com`, which Fastmail doesn't publish.
    @Test func query_returnsEmpty_whenFastmailHasNoSubmissionRecord() async throws {
        // Arrange
        let input = "_submission._tcp.fastmail.com"
        let expected: [SRVRecord] = []

        // Act
        let actual = try await SRVResolver().query(input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the published `imaps` record as the first result.
    //Case: When querying `_imaps._tcp.gmail.com`, which Gmail publishes.
    @Test func query_returnsIMAPSRecord_whenGmailPublishesIMAPS() async throws {
        // Arrange
        let input = "_imaps._tcp.gmail.com"
        let expected = "SRVRecord(host=imap.gmail.com, port=993, weight=0, priority=5)"

        // Act
        let actual = try await SRVResolver().query(input).first?.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return the published `submission` record as the first result.
    //Case: When querying `_submission._tcp.gmail.com`, which Gmail publishes.
    @Test func query_returnsSubmissionRecord_whenGmailPublishesSubmission() async throws {
        // Arrange
        let input = "_submission._tcp.gmail.com"
        let expected = "SRVRecord(host=smtp.gmail.com, port=587, weight=0, priority=5)"

        // Act
        let actual = try await SRVResolver().query(input).first?.description

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return no records.
    //Case: When querying `_autodiscover._tcp.gmail.com`, which Gmail doesn't publish.
    @Test func query_returnsEmpty_whenGmailHasNoAutodiscoverRecord() async throws {
        // Arrange
        let input = "_autodiscover._tcp.gmail.com"
        let expected: [SRVRecord] = []

        // Act
        let actual = try await SRVResolver().query(input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return no records.
    //Case: When querying `_jmap._tcp.gmail.com`, which Gmail doesn't publish.
    @Test func query_returnsEmpty_whenGmailHasNoJMAPRecord() async throws {
        // Arrange
        let input = "_jmap._tcp.gmail.com"
        let expected: [SRVRecord] = []

        // Act
        let actual = try await SRVResolver().query(input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return no records.
    //Case: When querying `_pop3._tcp.gmail.com`, which Gmail doesn't publish.
    @Test func query_returnsEmpty_whenGmailHasNoPOP3Record() async throws {
        // Arrange
        let input = "_pop3._tcp.gmail.com"
        let expected: [SRVRecord] = []

        // Act
        let actual = try await SRVResolver().query(input)

        // Assert
        #expect(actual == expected)
    }
}

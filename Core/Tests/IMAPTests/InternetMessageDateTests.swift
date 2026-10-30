// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import IMAP
import MIME
import NIOIMAPCore
import Testing

struct InternetMessageDateTests {
    //Expect: Preserve the parsed instant and the numeric time zone offset.
    //Case: When the time and negative numeric offset are separated by a space.
    // #expect(try InternetMessageDate(internetMessageDate: "Tue, 28 Nov 2023 08:55:43 -0800")
    //     == InternetMessageDate(Date(timeIntervalSince1970: 1701190543.0), timeZone: TimeZone(secondsFromGMT: -8 * 3600)!))
    @Test func init_preservesDateAndTimeZone_whenDateHasSpacedNegativeOffset() throws {
        // Arrange
        let input: NIOIMAPCore.InternetMessageDate = "Tue, 28 Nov 2023 08:55:43 -0800"
        let expected = InternetMessageDate(Date(timeIntervalSince1970: 1701190543.0), timeZone: TimeZone(secondsFromGMT: -8 * 3600)!)

        // Act
        let actual = try InternetMessageDate(internetMessageDate: input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Preserve the parsed instant and use GMT as the time zone.
    //Case: When the zero offset is followed by a parenthesized UTC abbreviation.
    @Test func init_preservesDateAndUsesGMT_whenDateHasParenthesizedUTC() throws {
        // Arrange
        let input: NIOIMAPCore.InternetMessageDate = "Fri, 23 Jan 2026 13:23:47 +0000 (UTC)"
        let expected = InternetMessageDate(Date(timeIntervalSince1970: 1769174627.0), timeZone: .gmt)

        // Act
        let actual = try InternetMessageDate(internetMessageDate: input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Preserve the parsed instant and the numeric time zone offset.
    //Case: When the negative numeric offset immediately follows the time without a space.
    @Test func init_preservesDateAndTimeZone_whenNegativeOffsetHasNoLeadingSpace() throws {
        // Arrange
        let input: NIOIMAPCore.InternetMessageDate = "Tue, 28 Nov 2023 08:55:43-0500"
        let expected = InternetMessageDate(Date(timeIntervalSince1970: 1701179743.0), timeZone: TimeZone(secondsFromGMT: -5 * 3600)!)

        // Act
        let actual = try InternetMessageDate(internetMessageDate: input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Preserve the parsed instant and the numeric time zone offset.
    //Case: When the positive numeric offset immediately follows the time without a space.
    @Test func init_preservesDateAndTimeZone_whenPositiveOffsetHasNoLeadingSpace() throws {
        // Arrange
        let input: NIOIMAPCore.InternetMessageDate = "Tue, 28 Nov 2023 08:55:43+0700"
        let expected = InternetMessageDate(Date(timeIntervalSince1970: 1701136543.0), timeZone: TimeZone(secondsFromGMT: 7 * 3600)!)

        // Act
        let actual = try InternetMessageDate(internetMessageDate: input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Preserve the parsed instant and use GMT as the time zone.
    //Case: When the date specifies its time zone using the GMT abbreviation.
    @Test func init_preservesDateAndUsesGMT_whenDateUsesGMTAbbreviation() throws {
        // Arrange
        let input: NIOIMAPCore.InternetMessageDate = "Sun, 25 Jan 2026 10:21:49 GMT"
        let expected = InternetMessageDate(Date(timeIntervalSince1970: 1769336509.0), timeZone: .gmt)

        // Act
        let actual = try InternetMessageDate(internetMessageDate: input)

        // Assert
        #expect(actual == expected)
    }
}

struct RFC822DateFormatterTests {
    //Expect: Format the local date and time with a space before the negative numeric offset.
    //Case: When the time zone is UTC-08:00.
    @Test func string_emitsSpacedNegativeOffset_whenTimeZoneIsUTCMinusEightHours() {
        // Arrange
        let input = InternetMessageDate(Date(timeIntervalSince1970: 1701190543.0), timeZone: TimeZone(secondsFromGMT: -8 * 3600)!)
        let formatter = RFC822DateFormatter()
        let expected = "Tue, 28 Nov 2023 08:55:43 -0800"

        // Act
        let actual = formatter.string(from: input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Format the GMT date and time with +0000 as the time zone offset.
    //Case: When the date is January 23, 2026 in GMT.
    @Test func string_emitsZeroNumericOffset_whenDateIsJanuary23InGMT() {
        // Arrange
        let input = InternetMessageDate(Date(timeIntervalSince1970: 1769174627.0), timeZone: .gmt)
        let formatter = RFC822DateFormatter()
        let expected = "Fri, 23 Jan 2026 13:23:47 +0000"

        // Act
        let actual = formatter.string(from: input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Format the local date and time with a space before the negative numeric offset.
    //Case: When the time zone is UTC-05:00.
    @Test func string_emitsSpacedNegativeOffset_whenTimeZoneIsUTCMinusFiveHours() {
        // Arrange
        let input = InternetMessageDate(Date(timeIntervalSince1970: 1701179743.0), timeZone: TimeZone(secondsFromGMT: -5 * 3600)!)
        let formatter = RFC822DateFormatter()
        let expected = "Tue, 28 Nov 2023 08:55:43 -0500"

        // Act
        let actual = formatter.string(from: input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Format the local date and time with a space before the positive numeric offset.
    //Case: When the time zone is UTC+07:00.
    @Test func string_emitsSpacedPositiveOffset_whenTimeZoneIsUTCPlusSevenHours() {
        // Arrange
        let input = InternetMessageDate(Date(timeIntervalSince1970: 1701136543.0), timeZone: TimeZone(secondsFromGMT: 7 * 3600)!)
        let formatter = RFC822DateFormatter()
        let expected = "Tue, 28 Nov 2023 08:55:43 +0700"

        // Act
        let actual = formatter.string(from: input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Format the GMT date and time with +0000 as the time zone offset.
    //Case: When the date is January 25, 2026 in GMT.
    @Test func string_emitsZeroNumericOffset_whenDateIsJanuary25InGMT() {
        // Arrange
        let input = InternetMessageDate(Date(timeIntervalSince1970: 1769336509.0), timeZone: .gmt)
        let formatter = RFC822DateFormatter()
        let expected = "Sun, 25 Jan 2026 10:21:49 +0000"

        // Act
        let actual = formatter.string(from: input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Preserve the parsed instant and the numeric time zone offset.
    //Case: When the time and negative numeric offset are separated by a space.
    @Test func internetMessageDate_preservesDateAndTimeZone_whenDateHasSpacedNegativeOffset() throws {
        // Arrange
        let input = "Tue, 28 Nov 2023 08:55:43 -0800"
        let formatter = RFC822DateFormatter()
        let expected = InternetMessageDate(Date(timeIntervalSince1970: 1701190543.0), timeZone: TimeZone(secondsFromGMT: -8 * 3600)!)

        // Act
        let actual = try formatter.internetMessageDate(from: input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Preserve the parsed instant and use GMT as the time zone.
    //Case: When the zero offset is followed by a parenthesized UTC abbreviation.
    @Test func internetMessageDate_preservesDateAndUsesGMT_whenDateHasParenthesizedUTC() throws {
        // Arrange
        let input = "Fri, 23 Jan 2026 13:23:47 +0000 (UTC)"
        let formatter = RFC822DateFormatter()
        let expected = InternetMessageDate(Date(timeIntervalSince1970: 1769174627.0), timeZone: .gmt)

        // Act
        let actual = try formatter.internetMessageDate(from: input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Preserve the parsed instant and the numeric time zone offset.
    //Case: When the negative numeric offset immediately follows the time without a space.
    @Test func internetMessageDate_preservesDateAndTimeZone_whenNegativeOffsetHasNoLeadingSpace() throws {
        // Arrange
        let input = "Tue, 28 Nov 2023 08:55:43-0500"
        let formatter = RFC822DateFormatter()
        let expected = InternetMessageDate(Date(timeIntervalSince1970: 1701179743.0), timeZone: TimeZone(secondsFromGMT: -5 * 3600)!)

        // Act
        let actual = try formatter.internetMessageDate(from: input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Preserve the parsed instant and the numeric time zone offset.
    //Case: When the positive numeric offset immediately follows the time without a space.
    @Test func internetMessageDate_preservesDateAndTimeZone_whenPositiveOffsetHasNoLeadingSpace() throws {
        // Arrange
        let input = "Tue, 28 Nov 2023 08:55:43+0700"
        let formatter = RFC822DateFormatter()
        let expected = InternetMessageDate(Date(timeIntervalSince1970: 1701136543.0), timeZone: TimeZone(secondsFromGMT: 7 * 3600)!)

        // Act
        let actual = try formatter.internetMessageDate(from: input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Preserve the parsed instant and use GMT as the time zone.
    //Case: When the date specifies its time zone using the GMT abbreviation.
    @Test func internetMessageDate_preservesDateAndUsesGMT_whenDateUsesGMTAbbreviation() throws {
        // Arrange
        let input = "Sun, 25 Jan 2026 10:21:49 GMT"
        let formatter = RFC822DateFormatter()
        let expected = InternetMessageDate(Date(timeIntervalSince1970: 1769336509.0), timeZone: .gmt)

        // Act
        let actual = try formatter.internetMessageDate(from: input)

        // Assert
        #expect(actual == expected)
    }
}

struct TimeZoneTests {
    //Expect: Return a time zone eight hours behind GMT.
    //Case: When the time and negative numeric offset are separated by a space.
    @Test func init_returnsNegativeEightHourOffset_whenDateHasSpacedNegativeOffset() throws {
        // Arrange
        let input = "Tue, 28 Nov 2023 08:55:43 -0800"
        let expected = TimeZone(secondsFromGMT: -8 * 3600)

        // Act
        let actual = try TimeZone(internetMessageDate: input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return GMT as the time zone.
    //Case: When the zero offset is followed by a parenthesized UTC abbreviation.
    @Test func init_returnsGMT_whenDateHasParenthesizedUTC() throws {
        // Arrange
        let input = "Fri, 23 Jan 2026 13:23:47 +0000 (UTC)"
        let expected = TimeZone.gmt

        // Act
        let actual = try TimeZone(internetMessageDate: input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return a time zone five hours behind GMT.
    //Case: When the negative numeric offset immediately follows the time without a space.
    @Test func init_returnsNegativeFiveHourOffset_whenNegativeOffsetHasNoLeadingSpace() throws {
        // Arrange
        let input = "Tue, 28 Nov 2023 08:55:43-0500"
        let expected = TimeZone(secondsFromGMT: -5 * 3600)

        // Act
        let actual = try TimeZone(internetMessageDate: input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return a time zone seven hours ahead of GMT.
    //Case: When the positive numeric offset immediately follows the time without a space.
    @Test func init_returnsPositiveSevenHourOffset_whenPositiveOffsetHasNoLeadingSpace() throws {
        // Arrange
        let input = "Tue, 28 Nov 2023 08:55:43+0700"
        let expected = TimeZone(secondsFromGMT: 7 * 3600)

        // Act
        let actual = try TimeZone(internetMessageDate: input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Return GMT as the time zone.
    //Case: When the date specifies its time zone using the GMT abbreviation.
    @Test func init_returnsGMT_whenDateUsesGMTAbbreviation() throws {
        // Arrange
        let input = "Sun, 25 Jan 2026 10:21:49 GMT"
        let expected = TimeZone.gmt

        // Act
        let actual = try TimeZone(internetMessageDate: input)

        // Assert
        #expect(actual == expected)
    }
}

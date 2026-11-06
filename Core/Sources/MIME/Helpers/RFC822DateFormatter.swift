// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A formatter that converts between `Date` and  [RFC 822](https://www.rfc-editor.org/rfc/rfc822#section-5.1) `date-time` string representation
///
/// The format is `Thu, 06 Nov 2025 21:05:50 +0000`.
///
/// - Important: The formatter doesn't set a locale or calendar, so it follows the device's. On a device set to French
///   it writes `jeu., 06 nov. 2025`, with a Thai Buddhist calendar the year is 2568, with a Japanese calendar the year
///   is 0007, and with Arabic digits the digits change. Those aren't valid RFC 822 dates, and the same device can't
///   read English dates in a header. It wraps a `DateFormatter`, whose time zone ``string(from:_:)`` changes on every
///   call, so one instance isn't safe to share between threads.
// TODO: Set `locale` to `en_US_POSIX` and `calendar` to Gregorian on the formatter, and create a formatter per
// call (#626).
public struct RFC822DateFormatter {
    /// The date format string the formatter uses.
    public var dateFormat: String { formatter.dateFormat }

    /// Format a date as [RFC 822](https://www.rfc-editor.org/rfc/rfc822) text.
    ///
    /// - Parameters:
    ///   - date: The date to format.
    ///   - timeZone: The time zone to write the date in, which also gives the offset at the end. Defaults to GMT.
    /// - Returns: The date as text.
    public func string(from date: Date, _ timeZone: TimeZone = .gmt) -> String {
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    /// Read [RFC 822](https://www.rfc-editor.org/rfc/rfc822) text as a date.
    ///
    /// Spaces are added before `+` and `-` so offsets like `-0500` parse, and a trailing comment in parentheses, such
    /// as `(CET)`, is ignored.
    ///
    /// - Parameter string: The date text, such as `Thu, 06 Nov 2025 21:05:50 -0500`.
    /// - Returns: The date.
    /// - Throws: `MIMEError.dateNotDecoded` if the text doesn't match the format.
    public func date(from string: String) throws -> Date {
        let string: String =
            string
            .replacingOccurrences(of: "+", with: " +")
            .replacingOccurrences(of: "-", with: " -")
            .replacingOccurrences(of: "  ", with: " ")
            .components(separatedBy: "(")[0]
            .trimmed()
        guard let date: Date = formatter.date(from: string) else {
            throw MIMEError.dateNotDecoded(string)
        }
        return date
    }

    /// Make a formatter that uses GMT.
    public init() {
        formatter = DateFormatter()
        formatter.dateFormat = .rfc822Format
        formatter.timeZone = .gmt
    }

    private let formatter: DateFormatter
}

/// Extends `Date` with "date-time" text, described in [RFC 822](https://www.rfc-editor.org/rfc/rfc822#section-5.1).
extension Date {
    /// The date as [RFC 822](https://www.rfc-editor.org/rfc/rfc822) text, such as the value of a `Date` header.
    ///
    /// - Parameter timeZone: The time zone to write the date in. Defaults to GMT.
    /// - Returns: The date as text, which follows the device's locale and calendar as ``RFC822DateFormatter``
    ///   describes.
    public func rfc822Format(_ timeZone: TimeZone = .gmt) -> String {
        RFC822DateFormatter().string(from: self, timeZone)
    }

    /// Read [RFC 822](https://www.rfc-editor.org/rfc/rfc822) text as a date.
    ///
    /// - Parameter string: The date text.
    /// - Throws: `MIMEError.dateNotDecoded` if the text doesn't match the format.
    public init(rfc822Format string: String) throws {
        self = try RFC822DateFormatter().date(from: string)
    }
}

extension String {
    static var rfc822Format: Self { "EEE, dd MMM yyyy HH:mm:ss Z" }  // RFC 822 date-time format
}

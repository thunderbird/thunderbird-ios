// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A formatter that converts between `Date` and  [RFC 822](https://www.rfc-editor.org/rfc/rfc822#section-5.1) `date-time` string representation
public struct RFC822DateFormatter {
    public var dateFormat: String { formatter.dateFormat }

    public func string(from date: Date, _ timeZone: TimeZone = .gmt) -> String {
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

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

    public init() {
        formatter = DateFormatter()
        formatter.dateFormat = .rfc822Format
        formatter.timeZone = .gmt
    }

    private let formatter: DateFormatter
}

/// Multipart "date-time" format described in [RFC 822](https://www.rfc-editor.org/rfc/rfc822#section-5.1)
extension Date {
    public func rfc822Format(_ timeZone: TimeZone = .gmt) -> String {
        RFC822DateFormatter().string(from: self, timeZone)
    }

    public init(rfc822Format string: String) throws {
        self = try RFC822DateFormatter().date(from: string)
    }
}

extension String {
    static var rfc822Format: Self { "EEE, dd MMM yyyy HH:mm:ss Z" }  // RFC 822 date-time format
}

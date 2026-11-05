// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// Formats an email's date either in full or as a "smart" date that depends on how long ago it was.
///
/// Email dates may be absolute or relative to the current date, based on the app's settings. Smart dates are
/// localized and read like this:
///
/// | Date | Smart date |
/// |---|---|
/// | Today | The time, such as "3:22 PM" |
/// | Yesterday | A relative phrase, such as "1 day ago" |
/// | Earlier this year | Month and day, such as "Nov 1" |
/// | A previous year | Month, day and year, such as "Aug 20, 2002" |
@MainActor
public struct SmartDateFormatter {
    /// Format a date for display.
    ///
    /// - Parameters:
    ///   - date: The date to format.
    ///   - isSmartDate: `true` for a smart date, `false` for the full numeric date, such as "11/4/2026".
    /// - Returns: The formatted date, localized.
    func dateFormatter(date: Date, isSmartDate: Bool) -> String {
        if isSmartDate {
            return smartDate(date: date)
        }
        return fullDateFormatter(date: date)
    }

    private func fullDateFormatter(date: Date) -> String {
        return date.formatted(date: .numeric, time: .omitted)
    }

    /// Describe a date relative to now, using the formats in the table above.
    ///
    /// - Returns: The time for today, a relative phrase for yesterday, month and day within the current calendar year,
    ///   and month, day and year before it. All are localized.
    private func smartDate(date: Date) -> String {
        if Calendar.autoupdatingCurrent.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        } else if Calendar.autoupdatingCurrent.isDateInYesterday(date) {
            let relativeDateFormatter = RelativeDateTimeFormatter()
            return relativeDateFormatter.localizedString(for: date, relativeTo: Date())
        } else if !Calendar.autoupdatingCurrent.isDate(date, equalTo: Date(), toGranularity: .year) {
            return date.formatted(.dateTime.month(.abbreviated).day().year())
        } else {
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
    }
}

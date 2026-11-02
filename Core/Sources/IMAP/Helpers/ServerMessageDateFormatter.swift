// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MIME
import NIOIMAPCore

/// A formatter that converts between `Date` and  `NIOIMAPCore.ServerMessageDate` string representation
struct ServerMessageDateFormatter {
    var dateFormat: String { "\(formatter.dateFormat!) \(String.serverMessageDate.offset)" }

    func string(from date: Date) -> String {
        "\(formatter.string(from: date)) \(String.serverMessageDate.offset)"
    }

    func date(from string: String) throws -> Date {
        let string: String =
            string
            .components(separatedBy: "+")[0]
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let date: Date = formatter.date(from: string) else {
            throw MIMEError.dateNotDecoded(string)
        }
        return date
    }

    init() {
        formatter = DateFormatter()
        formatter.dateFormat = .serverMessageDate.format
        formatter.timeZone = .gmt
    }

    private let formatter: DateFormatter
}

extension Date {
    func serverMessageDateFormat() -> String {
        ServerMessageDateFormatter().string(from: self)
    }

    init(serverMessageDate: ServerMessageDate) throws {
        self = try Self(serverMessageDate: serverMessageDate.debugDescription)
    }

    init(serverMessageDate string: String) throws {
        self = try ServerMessageDateFormatter().date(from: string)
    }
}

extension String {
    static var serverMessageDate: (format: Self, offset: Self) { ("dd-MMM-yyyy HH:mm:ss", "+0000") }
}

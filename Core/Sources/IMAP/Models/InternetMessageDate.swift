// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MIME
import NIOIMAPCore

public struct InternetMessageDate: CustomStringConvertible, Equatable, Sendable {
    public let date: Date
    public let timeZone: TimeZone

    public init(_ date: Date, timeZone: TimeZone = .current) {
        self.date = date
        self.timeZone = timeZone
    }

    init(internetMessageDate: NIOIMAPCore.InternetMessageDate?) throws {
        guard let internetMessageDate else {
            throw MIMEError.dateNotDecoded("nil")
        }
        self = try RFC822DateFormatter().internetMessageDate(from: String(internetMessageDate))
    }

    // MARK: CustomStringConvertible
    public var description: String { RFC822DateFormatter().string(from: self) }
}

extension RFC822DateFormatter {
    public func string(from internetMessageDate: InternetMessageDate) -> String {
        string(from: internetMessageDate.date, internetMessageDate.timeZone)
    }

    public func internetMessageDate(from string: String) throws -> InternetMessageDate {
        let date: Date = try self.date(from: string)
        let timeZone: TimeZone = try TimeZone(internetMessageDate: string)
        return InternetMessageDate(date, timeZone: timeZone)
    }
}

extension TimeZone {
    init(internetMessageDate string: String) throws {
        let string: String =
            string
            .replacingOccurrences(of: "+", with: " +")
            .replacingOccurrences(of: "-", with: " -")
            .replacingOccurrences(of: "(", with: " ")
            .replacingOccurrences(of: ")", with: "")
            .components(separatedBy: " ")
            .last!
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if string.hasPrefix("+") || string.hasPrefix("-"),
            let offset: Int = Int(string),
            let timeZone: Self = Self(secondsFromGMT: offset * 36)
        {
            self = timeZone  // Time zone from GMT offset; examples: -0800, +0000
        } else if let timeZone: Self = Self(abbreviation: string) {
            self = timeZone  // Time zone from 3-character abbreviation; examples: PDT, GMT
        } else {
            throw MIMEError.dateNotDecoded(string)
        }
    }
}

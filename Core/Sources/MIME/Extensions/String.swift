// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension String {

    /// Line is defined as a sequence of octets separated by a [CRLF](https://developer.mozilla.org/en-US/docs/Glossary/CRLF)
    /// Described in [RFC 2045](https://www.rfc-editor.org/rfc/rfc2045#section-2.10)
    public static var crlf: Self { "\r\n" }

    /// ASCII-compatible UUID string separator
    public static var separator: Self { "-" }

    /// ASCII representation, if `String` is ASCII
    public var ascii: Self? {
        guard let data: Data = data(using: .ascii) else {
            return nil
        }
        return Self(data: data, encoding: .ascii)
    }

    /// Capitalization case formats
    public enum Case: CaseIterable {
        case sentence, title
    }

    /// Overload capitalization with alternate case options
    public func capitalized(_ `case`: Case) -> Self {
        switch `case` {
        case .sentence: "\(prefix(1).capitalized)\(dropFirst())"
        case .title: capitalized
        }
    }

    /// Decode common HTML entities to `Character` equivalents.
    public func htmlEntitiesDecoded() -> Self {

        // Source - https://stackoverflow.com/a/30141700
        // Posted by Martin R, modified by community
        // Retrieved 2026-08-11, License - CC BY-SA 4.0

        // Convert the number in the string to the corresponding Unicode character.
        // Example: decodeNumeric("64", 10)   --> "@"
        //          decodeNumeric("20ac", 16) --> "€"
        func decodeNumeric(_ substring: Substring, base: Int) -> Character? {
            guard let value: UInt32 = UInt32(substring, radix: base),
                let scalar: UnicodeScalar = UnicodeScalar(value)
            else {
                return nil
            }
            return Character(scalar)
        }

        // Decode the HTML character entity to the corresponding Unicode character.
        // Example: decode("&#64;")    --> "@"
        //          decode("&#x20ac;") --> "€"
        //          decode("&lt;")     --> "<"
        //          decode("&foo;")    --> nil
        func decode(_ substring: Substring) -> Character? {
            if substring.lowercased().hasPrefix("&#x") {
                return decodeNumeric(substring.dropFirst(3).dropLast(), base: 16)
            } else if substring.hasPrefix("&#") {
                return decodeNumeric(substring.dropFirst(2).dropLast(), base: 10)
            } else {
                return Character(entity: "\(substring)")
            }
        }

        var result: Self = ""
        var position: Index = startIndex

        // Find next ampersand; copy characters preceding it to result
        while let ampRange: Range<Index> = self[position...].range(of: "&") {
            result.append(contentsOf: self[position..<ampRange.lowerBound])
            position = ampRange.lowerBound

            // Find next semicolon; copy characters between "&" and ";"
            guard let semiRange: Range<Index> = self[position...].range(of: ";") else {
                continue
            }
            let entity: Substring = self[position..<semiRange.upperBound]
            if let character: Character = decode(entity) {
                result.append(character)
                position = semiRange.upperBound
            } else {
                result.append(contentsOf: self[ampRange])
                position = ampRange.upperBound
            }
        }
        result.append(contentsOf: self[position...])  // Copy remaining characters to result:
        return result
    }

    /// Break email header value string into parameter keys and values.
    public var parameters: [Self: Self] {
        var parameters: [Self: Self] = [:]
        for parameter in components(separatedBy: ";") {
            guard let index: String.Index = parameter.firstIndex(of: "=") else {
                continue
            }
            let key: String = "\(parameter.prefix(upTo: index))".lowercased().trimmed()
            let value: String = "\(parameter.trimmed().dropFirst(key.count + 1))".removing(.quotes).trimmed()
            parameters[key] = value
        }
        return parameters
    }

    /// Decode any [RFC 2047](https://www.rfc-editor.org/rfc/rfc2047)-encoded email header string
    public func headerDecoded() throws -> Self {

        // Because encoding creates significantly longer strings, headers can be encoded in multiple segments
        // Allows selecting the shortest encoding method for arbitrary chunks
        let segments: [Self] = trimmed().components(separatedBy: "?= =?")
        if segments.count > 1 {
            let segments: [Self] = try segments.map {
                try "\(!$0.hasPrefix("=?") ? "=?" : "")\($0)\(!$0.hasSuffix("?=") ? "?=" : "")".headerDecoded()
            }
            return segments.joined(separator: "")
        }
        var string: Self = trimmed()
        guard string.hasPrefix("=?"), string.hasSuffix("?=") else {
            return self  // String not header-encoded; skip decoding
        }
        let components: [Self] = Array(string.components(separatedBy: "?").dropLast().dropFirst())
        guard components.count > 2 else {
            throw MIMEError.headerNotDecoded(string)
        }
        let encoding: Encoding = try Encoding(components[0])
        let contentTransferEncoding: ContentTransferEncoding = try ContentTransferEncoding(components[1])
        string = components.dropFirst(2).joined(separator: "?")
        switch contentTransferEncoding {
        case .base64:
            return try Self(base64: string, encoding: encoding)
        case .quotedPrintable:
            return try Self(quotedPrintable: string, encoding: encoding)
        default:
            throw MIMEError.headerNotDecoded(string)
        }
    }

    /// Encode any string as a UTF-8, base64 email header.
    /// Described in [RFC 2047](https://www.rfc-editor.org/rfc/rfc2047)
    public func headerEncoded() throws -> Self {
        if let data: Data = data(using: .ascii),
            let string: Self = Self(data: data, encoding: .ascii)
        {
            return string  // Already plain ASCII
        }
        guard let data: Data = data(using: .utf8) else {
            throw MIMEError.dataNotFound
        }
        return [
            "=",
            "UTF-8",
            "B",
            data.base64EncodedString(),
            "="
        ].joined(separator: "?")
    }

    /// Decode quoted-printable data to given `String.Encoding`.
    public init(quotedPrintable data: Data, encoding: Encoding = .utf8) throws {
        guard let string: String = String(data: data, encoding: .ascii) else {
            throw MIMEError.dataNotDecoded(data, encoding: encoding)
        }
        self = try Self(quotedPrintable: string, encoding: encoding)
    }

    /// Decode quoted-printable string to given `String.Encoding`.
    public init(quotedPrintable string: Self, encoding: Encoding = .utf8) throws {
        self = try string.decodingQuotedPrintable(to: encoding)
    }

    /// Decode base64 data to given `String.Encoding`.
    public init(base64 data: Data, encoding: Encoding = .utf8) throws {
        guard let string: String = String(data: data, encoding: .ascii) else {
            throw MIMEError.dataNotDecoded(data, encoding: encoding)
        }
        self = try string.decodingBase64(to: encoding)
    }

    /// Decode base64 string to given `String.Encoding`.
    public init(base64 string: Self, encoding: Encoding = .utf8) throws {
        self = try string.decodingBase64(to: encoding)
    }

    func decodingBase64(to encoding: Encoding = .utf8) throws -> Self {
        guard let data: Data = Data(base64Encoded: self, options: .ignoreUnknownCharacters) else {
            if let data: Data = self.data(using: .ascii) {
                throw MIMEError.dataNotDecoded(data, encoding: encoding)
            } else {
                throw MIMEError.dataNotFound
            }
        }
        guard let string: Self = Self(data: data, encoding: encoding) else {
            throw MIMEError.dataNotDecoded(data, encoding: encoding)
        }
        return string
    }

    func decodingQuotedPrintable(to encoding: Encoding = .utf8) throws -> Self {
        try replacingOccurrences(of: "= ", with: "=\n")  // Fix failed line-limit wrapping
            .replacingOccurrences(of: "=\r\n", with: "")  // Remove quoted-printable line-limit wrapping
            .replacingOccurrences(of: "=\n", with: "")  // Remove quoted-printable line-limit wrapping
            .decodingQuotedPrintableEncoding(to: encoding)
    }

    func decodingQuotedPrintableEncoding(to encoding: Encoding = .utf8) throws -> Self {

        // Source - https://stackoverflow.com/a/32827598
        // Posted by Martin R, modified by community
        // Retrieved 2026-07-28, License - CC BY-SA 4.0
        var result: Self = ""
        var position: Index = startIndex

        // Find next "=" control character; copy characters preceding it to the result
        while let range: Range<Index> = range(of: "=", range: position..<endIndex) {
            result.append(contentsOf: self[position..<range.lowerBound])
            position = range.lowerBound

            // Decode one or more successive "=HH" sequences to a byte array
            var data: Data = Data()
            repeat {
                let hexCode: Substring = self[position...].dropFirst().prefix(2)
                guard hexCode.count == 2, let byte: UInt8 = UInt8(hexCode, radix: 16) else {
                    throw MIMEError.dataNotQuotedPrintable
                }
                data.append(byte)
                position = index(position, offsetBy: 3)
            } while position != endIndex && self[position] == "="

            // Convert the byte array to a string; append it to the result
            guard let string: Self = Self(data: data, encoding: encoding) else {
                throw MIMEError.dataNotQuotedPrintable
            }
            result.append(contentsOf: string)
        }
        result.append(contentsOf: self[position..<endIndex])
        return result
    }

    func removing(_ characters: [Character]) -> Self {
        var string: Self = "\(self)"
        for character in characters {
            string = string.replacingOccurrences(of: "\(character)", with: "")
        }
        return string
    }

    func unwrapping(_ prefix: String, _ suffix: String) -> Self {
        var string: Self = "\(self)"
        if hasPrefix(prefix) {
            string = "\(string.dropFirst(prefix.count))"
        }
        if hasSuffix(suffix) {
            string = "\(string.dropLast(suffix.count))"
        }
        return string
    }

    func trimmed() -> Self {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public var crlf: String { .crlf }

extension [Character] {
    static var quotes: Self { ["\"", "'"] }
}

extension ContentTransferEncoding {
    init(_ string: String) throws {
        switch string.trimmed().uppercased() {
        case "B":
            self = .base64
        case "Q":
            self = .quotedPrintable
        default:
            throw MIMEError.headerNotDecoded(string)
        }
    }
}

extension String.Encoding {

    // TODO: Use `String.Encoding.init(ianaName:)` instead, once available in 26.4 SDK
    // https://developer.apple.com/documentation/swift/string/encoding/init(iananame:)
    init(_ string: String) throws {
        switch string.trimmed().uppercased() {
        case "US-ASCII":
            self = .ascii
        case "ISO-8859-1":
            self = .isoLatin1
        case "ISO-8859-2":
            self = .isoLatin2
        case "UTF-8":
            self = .utf8
        default:
            throw MIMEError.headerNotDecoded(string)
        }
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Extends `String` with the helpers MIME needs: line endings, ASCII checks, header parameters, RFC 2047 encoded words,
/// HTML entities, and base64 and quoted-printable decoding.
extension String {

    /// Line is defined as a sequence of octets separated by a [CRLF](https://developer.mozilla.org/en-US/docs/Glossary/CRLF)
    /// Described in [RFC 2045](https://www.rfc-editor.org/rfc/rfc2045#section-2.10)
    public static var crlf: Self { "\r\n" }

    /// ASCII-compatible UUID string separator
    public static var separator: Self { "-" }

    /// ASCII representation, if `String` is ASCII
    ///
    /// - Returns: The same text, or `nil` if any character can't be written as ASCII.
    public var ascii: Self? {
        guard let data: Data = data(using: .ascii) else {
            return nil
        }
        return Self(data: data, encoding: .ascii)
    }

    /// Capitalization case formats
    ///
    /// `sentence` capitalizes only the first letter and leaves the rest as it is. `title` capitalizes the first letter
    /// of every word, like `capitalized`.
    public enum Case: CaseIterable {
        case sentence, title
    }

    /// Overload capitalization with alternate case options
    ///
    /// - Parameter case: The capitalization to apply.
    /// - Returns: The text capitalized in that format.
    public func capitalized(_ `case`: Case) -> Self {
        switch `case` {
        case .sentence: "\(prefix(1).capitalized)\(dropFirst())"
        case .title: capitalized
        }
    }

    /// Decode common HTML entities to `Character` equivalents.
    ///
    /// Handles decimal (`&#64;`) and hexadecimal (`&#x20ac;`) numeric entities, and the named entities that
    /// `Character.init(entity:)` knows. An entity that isn't recognized is left as it is.
    ///
    /// - Returns: The text with the entities replaced.
    /// - Important: A string with an `&` that has no `;` anywhere after it never finishes: the loop doesn't move past
    ///   that `&`. `"AT&T rocks".htmlEntitiesDecoded()` hangs, and the email preview text goes through this function.
    // TODO: Fix the infinite loop: stop (`break`) instead of `continue` when no `;` follows an `&`. This hangs the app
    // on an email whose text has an `&` after its last `;` (#625).
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
    ///
    /// The text is split at every `;`, and each piece with an `=` becomes a parameter. Keys are lowercased and trimmed.
    /// Values keep their case, and every `"` and `'` is removed from them.
    ///
    /// - Returns: The parameters by name. Pieces with no `=`, such as the leading `text/plain`, are skipped.
    /// - Important: This isn't a full parameter parser. A `;` inside a quoted value ends the value there
    ///   (`filename="a;b.pdf"` gives `a`), an apostrophe in a value is removed (`Bob's` gives `Bobs`, which would also
    ///   change a multipart boundary containing one), and spaces around `=` leave the `=` in the value
    ///   (`filename = x.txt` gives `= x.txt`).
    // TODO: Parse quoted strings and escapes (RFC 2045), allow spaces around `=`, and support RFC 2231 extended
    // values (#629).
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
    ///
    /// Reads a value that is one encoded word, such as `=?UTF-8?B?w6l0w6k=?=`, or several of them separated by spaces.
    ///
    /// - Returns: The decoded text, or the original text if it isn't made entirely of encoded words.
    /// - Throws: `MIMEError.headerNotDecoded` if the word is malformed, uses an encoding other than `B` or `Q`, or uses
    ///   a charset other than US-ASCII, ISO-8859-1, ISO-8859-2 or UTF-8, plus the errors from decoding the content.
    /// - Important: Encoded words mixed with other text aren't decoded: `=?UTF-8?Q?Jos=C3=A9?= <jose@example.com>` and
    ///   `Re: =?UTF-8?B?w6l0w6k=?=` come back unchanged. In `Q` words, `_` should mean a space but stays an underscore
    ///   (`Hello_World`). Common charsets such as `windows-1252` throw.
    // TODO: Find encoded words inside any header text (RFC 2047 section 6), turn `_` into a space in `Q` words, and
    // support more charsets (#630).
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
    ///
    /// - Returns: The text unchanged if it is already ASCII, otherwise one `=?UTF-8?B?...?=` encoded word.
    /// - Throws: `MIMEError.dataNotFound` if the text can't be written as UTF-8.
    /// - Important: The whole string becomes one encoded word, so apply it to a display name and not to a complete
    ///   address like `José <jose@example.com>`, and a long string makes a word longer than the 75 characters RFC 2047
    ///   allows.
    // TODO: Split long text into several encoded words of at most 75 characters. Nothing in the app calls this yet.
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
    ///
    /// - Parameters:
    ///   - data: The quoted-printable content as ASCII bytes.
    ///   - encoding: The character encoding of the decoded bytes. Defaults to UTF-8.
    /// - Throws: `MIMEError.dataNotDecoded` if the bytes aren't ASCII, and the errors from
    ///   `init(quotedPrintable:encoding:)` with text.
    public init(quotedPrintable data: Data, encoding: Encoding = .utf8) throws {
        guard let string: String = String(data: data, encoding: .ascii) else {
            throw MIMEError.dataNotDecoded(data, encoding: encoding)
        }
        self = try Self(quotedPrintable: string, encoding: encoding)
    }

    /// Decode quoted-printable string to given `String.Encoding`.
    ///
    /// Soft line breaks (`=` at the end of a line) are removed first, and so is a `=` followed by a space, which
    /// repairs lines that were wrapped badly. Then each run of `=HH` hex escapes is turned into bytes and read with
    /// `encoding`.
    ///
    /// - Parameters:
    ///   - string: The quoted-printable content.
    ///   - encoding: The character encoding of the decoded bytes. Defaults to UTF-8.
    /// - Throws: `MIMEError.dataNotQuotedPrintable` if any `=` isn't followed by two hex digits, or the bytes aren't
    ///   valid in `encoding`. One stray `=` makes the whole decode fail.
    public init(quotedPrintable string: Self, encoding: Encoding = .utf8) throws {
        self = try string.decodingQuotedPrintable(to: encoding)
    }

    /// Decode base64 data to given `String.Encoding`.
    ///
    /// - Parameters:
    ///   - data: The base64 content as ASCII bytes.
    ///   - encoding: The character encoding of the decoded bytes. Defaults to UTF-8.
    /// - Throws: `MIMEError.dataNotDecoded` if the bytes aren't ASCII, and the errors from `init(base64:encoding:)`
    ///   with text.
    public init(base64 data: Data, encoding: Encoding = .utf8) throws {
        guard let string: String = String(data: data, encoding: .ascii) else {
            throw MIMEError.dataNotDecoded(data, encoding: encoding)
        }
        self = try string.decodingBase64(to: encoding)
    }

    /// Decode base64 string to given `String.Encoding`.
    ///
    /// Characters that aren't part of base64, such as line breaks, are ignored.
    ///
    /// - Parameters:
    ///   - string: The base64 content.
    ///   - encoding: The character encoding of the decoded bytes. Defaults to UTF-8.
    /// - Throws: `MIMEError.dataNotDecoded` if the text isn't base64 or the bytes aren't valid in `encoding`, or
    ///   `MIMEError.dataNotFound` if the text isn't base64 and also isn't ASCII.
    public init(base64 string: Self, encoding: Encoding = .utf8) throws {
        self = try string.decodingBase64(to: encoding)
    }

    /// Decode base64 text to a string; see `init(base64:encoding:)`.
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

    /// Remove soft line breaks, then decode the `=HH` escapes; see `init(quotedPrintable:encoding:)`.
    func decodingQuotedPrintable(to encoding: Encoding = .utf8) throws -> Self {
        try replacingOccurrences(of: "= ", with: "=\n")  // Fix failed line-limit wrapping
            .replacingOccurrences(of: "=\r\n", with: "")  // Remove quoted-printable line-limit wrapping
            .replacingOccurrences(of: "=\n", with: "")  // Remove quoted-printable line-limit wrapping
            .decodingQuotedPrintableEncoding(to: encoding)
    }

    /// Replace each run of `=HH` escapes with the characters the bytes spell in `encoding`.
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

    /// The text with every occurrence of the given characters removed.
    func removing(_ characters: [Character]) -> Self {
        var string: Self = "\(self)"
        for character in characters {
            string = string.replacingOccurrences(of: "\(character)", with: "")
        }
        return string
    }

    /// The text without the given prefix and suffix, each removed only if present.
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

    /// The text without leading and trailing whitespace and line breaks.
    func trimmed() -> Self {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Shorthand for `String.crlf`, a carriage return and line feed.
public var crlf: String { .crlf }

extension [Character] {
    static var quotes: Self { ["\"", "'"] }
}

/// Extends `ContentTransferEncoding` with the one-letter names RFC 2047 uses in encoded words.
extension ContentTransferEncoding {
    /// Read the `B` or `Q` of an encoded word.
    ///
    /// - Parameter string: `B` for base64 or `Q` for quoted-printable, without regard to case.
    /// - Throws: `MIMEError.headerNotDecoded` for any other letter.
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

/// Extends `String.Encoding` with reading the charset name of an encoded word.
extension String.Encoding {

    /// Read a charset name.
    ///
    /// - Parameter string: `US-ASCII`, `ISO-8859-1`, `ISO-8859-2` or `UTF-8`, without regard to case.
    /// - Throws: `MIMEError.headerNotDecoded` for any other charset.
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

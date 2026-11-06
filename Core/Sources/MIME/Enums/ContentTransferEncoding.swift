// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// How a MIME part's content is encoded for transfer, described in
/// [RFC 2045](https://www.rfc-editor.org/rfc/rfc2045#section-6).
///
/// A multipart email body must be ASCII in transfer, so the readable encodings are the ones email uses in practice,
/// especially `base64` and `quotedPrintable`. The raw value is the name used in the Content-Transfer-Encoding header.
///
/// - Note: This library doesn't encode content itself. A ``Part`` holds data that has already been encoded, and no code
///   in the app writes parts yet.
public enum ContentTransferEncoding: String, CaseIterable, CustomStringConvertible, RawRepresentable, Sendable {
    /// 7-bit US-ASCII text (`7bit`).
    case ascii = "7bit"
    /// Binary data written as base64 text.
    case base64
    /// Arbitrary bytes with no encoding.
    case binary
    /// 8-bit text (`8bit`).
    case data = "8bit"
    /// Mostly-ASCII text where other bytes are written as `=` and two hex digits (`quoted-printable`).
    case quotedPrintable = "quoted-printable"

    /// 7-bit ASCII, the encoding a part has when its header is missing.
    public static var `default`: Self { .ascii }

    // MARK: CustomStringConvertible
    public var description: String { rawValue }

    // MARK: RawRepresentable
    /// Look up an encoding by its header name.
    ///
    /// - Parameter rawValue: The header value. Matching ignores case and surrounding whitespace.
    /// - Returns: The matching encoding, or `nil` if the name isn't one of the five.
    public init?(rawValue: String) {
        let rawValue: String = rawValue.lowercased().trimmed()
        guard let encoding: Self = Self.allCases.filter({ $0.rawValue == rawValue }).first else {
            return nil
        }
        self = encoding
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Multipart email body must be ASCII in transfer. Parts encoded by this library use `base64` transfer encoding exclusively, but we expect to decode parts in any of the enumerated encodings, especially `quotedPrintable`.
public enum ContentTransferEncoding: String, CaseIterable, CustomStringConvertible, RawRepresentable, Sendable {
    case ascii = "7bit"
    case base64
    case binary
    case data = "8bit"
    case quotedPrintable = "quoted-printable"

    public static var `default`: Self { .ascii }

    // MARK: CustomStringConvertible
    public var description: String { rawValue }

    // MARK: RawRepresentable
    public init?(rawValue: String) {
        let rawValue: String = rawValue.lowercased().trimmed()
        guard let encoding: Self = Self.allCases.filter({ $0.rawValue == rawValue }).first else {
            return nil
        }
        self = encoding
    }
}

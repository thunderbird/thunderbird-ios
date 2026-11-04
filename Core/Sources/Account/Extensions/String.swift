// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Extends `String` for HTML manipulation and MIME integration
///
/// These helpers support inlining related attachments into HTML, extracting
/// HTML attributes, and stripping tags for generating plain text.
extension String {
    /// Returns a copy of the string with all matching attachment links inlined as data URLs.
    ///
    /// - Parameter attachments: The attachments to inline into the HTML string.
    /// - Returns: A new string with each attachment link replaced by a `data:` URL.
    func inlining(attachments: [EmailAttachment]) -> Self {
        var string: Self = self
        for attachment in attachments {
            string = string.inlining(attachment: attachment)
        }
        return string
    }

    /// Returns a copy of the string with a single attachment's links inlined as a data URL.
    ///
    /// - Parameter attachment: The attachment whose links should be replaced.
    /// - Returns: A new string with occurrences of the attachment links replaced by a `data:` URL.
    func inlining(attachment: EmailAttachment) -> Self {
        var string: Self = self
        for link in attachment.links {
            string = string.replacingOccurrences(of: link, with: URL(attachment: attachment).absoluteString)
        }
        return string
    }

    /// A name/value pair representing a single HTML attribute.
    typealias HTMLAttribute = (name: Self, value: Self)

    /// Extracts name/value pairs for attributes from the string.
    ///
    /// - Returns: An array of `(name, value)` tuples for attributes found.
    func htmlAttributes() -> [HTMLAttribute] {
        // Source - https://stackoverflow.com/a/317081
        // Posted by VonC, modified by community
        // Retrieved 2026-08-14, License - CC BY-SA 4.0
        matches(of: /([\w|data-]+)=["']?((?:.(?!["']?\s+(?:\S+)=|\s*\/?[>"']))+.)["']?/)
            .map { ("\($0.1)", "\($0.2)") }
    }

    /// Returns a string with all HTML tags removed and whitespace-normalized lines.
    ///
    /// - Returns: A plain text string with tags removed and empty lines filtered out.
    func htmlTagsStripped() -> Self {
        replacing(/<[^>]*>/, with: "")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}

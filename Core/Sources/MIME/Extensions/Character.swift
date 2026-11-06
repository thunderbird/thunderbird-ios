// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Extends `Character` with decoding of named HTML character entities.
extension Character {

    /// Decode [HTML entity](https://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references) to represented `Character`.
    ///
    /// - Parameter entity: A named entity such as `&amp;` or `&eacute;`. The closing semicolon is optional.
    /// - Returns: The character, or `nil` if the entity isn't one of the 68 common ones in the library's table. Numeric
    ///   entities such as `&#64;` aren't handled here; `String.htmlEntitiesDecoded()` decodes those.
    /// - Note: `&ensp;` and `&emsp;` decode to an ordinary space, not to the wider en and em space characters.
    public init?(entity: String) {
        let entity: String = "\(entity);".replacingOccurrences(of: ";;", with: ";")  // Force closing semicolon
        guard let character: Self = entities[entity] else {
            return nil
        }
        self = character
    }
}

// Common HTML entities: https://htmlentities.io/articles/html-entities-list-reference
private let entities: [String: Character] = [

    // Reserved
    "&quot;": "\"",
    "&amp;": "&",
    "&apos;": "'",
    "&lt;": "<",
    "&gt;": ">",

    // Invisible
    "&nbsp;": "\u{00a0}",
    "&ensp;": " ",
    "&emsp;": " ",

    // Currency
    "&cent;": "¢",
    "&pound;": "£",
    "&curren;": "¤",
    "&yen;": "¥",
    "&euro;": "€",

    // Punctuation
    "&ndash;": "–",
    "&mdash;": "—",
    "&hellip;": "…",
    "&lsquo;": "‘",
    "&rsquo;": "’",
    "&ldquo;": "“",
    "&rdquo;": "”",
    "&laquo;": "«",
    "&raquo;": "»",
    "&middot;": "·",
    "&bull;": "•",
    "&dagger;": "†",
    "&sect;": "§",
    "&para;": "¶",
    "&iexcl;": "¡",
    "&iquest;": "¿",

    // Math
    "&times;": "×",
    "&divide;": "÷",
    "&plusmn;": "±",
    "&minus;": "−",
    "&asymp;": "≈",
    "&ne;": "≠",
    "&le;": "≤",
    "&ge;": "≥",
    "&infin;": "∞",
    "&sum;": "∑",
    "&radic;": "√",
    "&int;": "∫",
    "&deg;": "°",

    // Arrow
    "&larr;": "←",
    "&uarr;": "↑",
    "&rarr;": "→",
    "&darr;": "↓",
    "&harr;": "↔",
    "&lArr;": "⇐",
    "&rArr;": "⇒",
    "&hArr;": "⇔",

    // Greek
    "&alpha;": "α",
    "&beta;": "β",
    "&gamma;": "γ",
    "&delta;": "δ",
    "&pi;": "π",
    "&sigma;": "σ",
    "&phi;": "φ",
    "&omega;": "ω",
    "&Delta;": "Δ",
    "&Sigma;": "Σ",
    "&Omega;": "Ω",

    // Other
    "&copy;": "©",
    "&reg;": "®",
    "&trade;": "™",
    "&micro;": "µ",
    "&not;": "¬",
    "&hearts;": "♥",
    "&diams;": "♦"
]

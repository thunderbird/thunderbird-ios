// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Extends `URLComponents` with query encoding that form decoders read back unchanged.
extension URLComponents {
    /// Set the query items, percent-encoding `+` as `%2B` too.
    ///
    /// `URLComponents` leaves `+` unescaped because [RFC 3986](https://www.rfc-editor.org/rfc/rfc3986#section-3.4)
    /// allows it in a query, but servers that decode the query or
    /// a form body as `application/x-www-form-urlencoded` read it as a space. Encoding it keeps values such as
    /// `user+tag@example.com` intact.
    ///
    /// For example, `emailaddress=user+tag@example.com` is read by the server as `user tag@example.com`, while
    /// `emailaddress=user%2Btag@example.com` is read as `user+tag@example.com`. The `+`-as-space rule dates from HTML
    /// form submissions and still applies to OAuth2 token requests and most web servers' query parsing.
    /// Browsers behave the same way; see [MDN: Preserving plus signs](https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams#preserving_plus_signs).
    ///
    /// - Parameter queryItems: Items to set, or `nil` to remove the query.
    mutating func setQueryItemsEncodingPlus(_ queryItems: [URLQueryItem]?) {
        self.queryItems = queryItems
        percentEncodedQuery = percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")  // Only values can contain an unescaped `+`
    }
}

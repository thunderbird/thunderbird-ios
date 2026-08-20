// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension URLRequest {
    public static func token(_ request: OAuth2.Request, code: String, pkce: OAuth2.PKCE) throws -> Self {
        guard
            var components: URLComponents = URLComponents(
                url: request.tokenURL(code, pkce: pkce),
                resolvingAgainstBaseURL: false
            ), let httpBody: Data = components.percentEncodedQuery?.data(using: .utf8)
        else {
            throw URLError(.badURL)
        }
        components.queryItems = nil
        var request: Self = Self(url: components.url!)
        request.httpMethod = "POST"
        request.httpBody = httpBody
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        return request
    }

    public static func refreshToken(_ request: OAuth2.Request, refreshToken: String) throws -> Self {
        guard
            var components: URLComponents = URLComponents(
                url: request.refreshTokenURL(refreshToken),
                resolvingAgainstBaseURL: false
            ), let httpBody: Data = components.percentEncodedQuery?.data(using: .utf8)
        else {
            throw URLError(.badURL)
        }
        components.queryItems = nil
        var request: Self = Self(url: components.url!)
        request.httpMethod = "POST"
        request.httpBody = httpBody
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        return request
    }
}

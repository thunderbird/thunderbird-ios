// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension URLRequest {

    /// Request one or more operations from a  JMAP service.
    /// - Parameter methods: One or more ``Method``s for JMAP service to perform
    /// - Parameter url: API endpoint URL from ``Session``
    /// - Parameter authorization: ``Authorization`` credentials or token for request header
    /// - Returns: `URLRequest` configured to  POST to JMAP service provider
    public static func jmapAPI(_ methods: [any Method], url: URL, authorization: Authorization) throws -> Self {
        guard !methods.isEmpty else {
            throw MethodError.unknownMethod
        }
        guard !authorization.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }
        let object: [String: Any] = [
            "using": methods.using.map { $0.id },
            "methodCalls": methods.map { $0.object }
        ]
        var request: Self = Self(url: url)
        request.setJMAPHeaders(authorization: authorization)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: object)
        return request
    }

    /// Request JMAP session object from a service provider.
    /// - Parameter server: ``Server`` configuration for JMAP service provider
    /// - Returns: `URLRequest` configured to GET an authenticated session with a JMAP service provider
    public static func jmapSession(server: Server) throws -> Self {
        try jmapSession(host: server.host, port: server.port, authorization: server.authorization ?? .empty)
    }

    /// Request JMAP session object from a service provider.
    /// - Parameter host: Host name of the JMAP service provider; e.g., `api.fastmail.com`
    /// - Parameter authorization: ``Authorization`` credentials or token for request header
    /// - Returns: `URLRequest` configured to GET an authenticated session with a JMAP service provider
    public static func jmapSession(host: String, port: Int? = nil, authorization: Authorization) throws -> Self {
        guard !authorization.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }
        var request: Self = Self(url: try .jmapSession(host: host, port: port))
        request.setJMAPHeaders(authorization: authorization)
        return request
    }

    mutating func setJMAPHeaders(authorization: Authorization) {
        setAuthorization(authorization)
        setAcceptLanguage()
        setContentType()
        setAccept()
    }

    // Authorize HTTP request with session OAuth token
    mutating func setAuthorization(_ value: Authorization) {
        setValue(value.description, forHTTPHeaderField: "Authorization")
    }

    // Ask JMAP server to [localize user-visible strings](https://jmap.io/spec-core.html#localisation-of-user-visible-strings) according to device's configured locales.
    mutating func setAcceptLanguage(_ value: String = Locale.acceptedLanguages()) {
        setValue(value, forHTTPHeaderField: "Accept-Language")
    }

    // Declare HTTP request body content as JSON
    mutating func setContentType(_ value: String = "application/json; charset=utf-8") {
        setValue(value, forHTTPHeaderField: "Content-Type")
    }

    // Ask JMAP server to serialize HTTP response as JSON
    mutating func setAccept(_ value: String = "application/json") {
        setValue(value, forHTTPHeaderField: "Accept")
    }
}

private extension [any Method] {

    // Compile unique list of all capabilities used by methods in request
    var using: [Capability.Key] {
        var using: Set<Capability.Key> = []
        for key in map({ $0.using }).joined() {
            using.insert(key)
        }
        return using.map { $0 }
    }
}

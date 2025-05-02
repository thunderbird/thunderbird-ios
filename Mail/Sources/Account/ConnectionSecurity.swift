public enum ConnectionSecurity: String, Codable, CaseIterable, CustomStringConvertible {
    case startTLS = "STARTTLS"
    case tls = "SSL/TLS"
    case none

    // MARK: CustomStringConvertible
    public var description: String { rawValue }
}

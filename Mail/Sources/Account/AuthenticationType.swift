public enum AuthenticationType: String, Codable, CaseIterable, CustomStringConvertible {
    case password
    case passwordEncrypted = "encrypted password"
    case tlsCertificate = "TLS certificate"
    case oAuth2 = "OAuth2"
    case none

    // MARK: CustomStringConvertible
    public var description: String { rawValue }
}

import Autoconfiguration

public enum AuthenticationType: String, Codable, CaseIterable, CustomStringConvertible, Identifiable {
    case password
    case oAuth2 = "OAuth2"
    case none

    // MARK: CustomStringConvertible
    public var description: String { rawValue }

    // MARK: Identifiable
    public var id: String { rawValue }
}

extension AuthenticationType {
    init(_ authentication: [EmailProvider.Server.Authentication]) {
        if authentication.contains(.oAuth2) {
            self = .oAuth2  // Prefer OAuth2
        } else if authentication.contains(.passwordCleartext) {
            self = .password
        } else {
            self = .none
        }
    }
}

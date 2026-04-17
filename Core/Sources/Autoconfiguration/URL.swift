import Foundation

extension URL {
    /// Generate the appropriate autoconfig URL for a given source and email address.
    public static func autoconfig(_ emailAddress: String, source: Source = .ispDB) throws -> Self {
        switch source {
        case .provider: try provider(emailAddress)
        case .wellKnown: try wellKnown(emailAddress)
        case .ispDB: try ispDB(emailAddress)
        }
    }

    static func provider(_ emailAddress: String) throws -> Self {
        let host: String = try emailAddress.host
        guard let url: URL = URL(string: "https://autoconfig.\(host)/mail/config-v1.1.xml") else {
            throw URLError(.unsupportedURL)
        }
        return emailAddress != host
            ? url.appending(queryItems: [
                URLQueryItem(name: "emailaddress", value: emailAddress)
            ]) : url
    }

    static func wellKnown(_ emailAddress: String) throws -> Self {
        let host: String = try emailAddress.host
        guard let url: URL = URL(string: "https://\(host)/.well-known/autoconfig/mail/config-v1.1.xml") else {
            throw URLError(.unsupportedURL)
        }
        return url
    }

    static func ispDB(_ emailAddress: String) throws -> Self {
        let host: String = try emailAddress.host
        guard let url: URL = URL(string: "https://autoconfig.thunderbird.net/v1.1/\(host)") else {
            throw URLError(.unsupportedURL)
        }
        return url
    }
}

extension URL {
    static let suffixList: Self = Self(string: "https://publicsuffix.org/list/public_suffix_list.dat")!
}

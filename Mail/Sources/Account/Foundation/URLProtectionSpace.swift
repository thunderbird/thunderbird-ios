import Foundation

extension URLProtectionSpace {

    ///  Named secure realm for Thunderbird accounts
    static let account: URLProtectionSpace = URLProtectionSpace(host: "thunderbird.net")

    convenience init(host: String) {
        self.init(host: host, port: 0, protocol: "https", realm: nil, authenticationMethod: nil)
    }
}

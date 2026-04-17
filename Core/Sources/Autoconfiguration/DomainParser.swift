import Foundation

struct DomainParser {
    let domain: String
    let host: String
    let suffix: String

    init(_ emailAddress: String, suffixList: [String]) throws {
        let host: String = try emailAddress.host
        try self.init(host: host, suffixList: suffixList)
    }

    init(host: String, suffixList: [String]) throws {
        guard let suffix: String = suffixList.filter({ host.hasSuffix(".\($0)") }).last else {
            throw URLError(.dnsLookupFailed)
        }
        let segments: (host: [String], suffix: [String]) = (host.segments, suffix.segments)
        self.domain = segments.host.dropFirst(segments.host.count - (segments.suffix.count + 1)).joined(separator: ".")
        self.host = host
        self.suffix = suffix
    }
}

private extension String {
    var segments: [Self] { components(separatedBy: ".") }
}

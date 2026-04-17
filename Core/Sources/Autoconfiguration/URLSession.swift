import Foundation

extension URLSession {
    /// Query multiple autoconfig sources for a given email address.
    public func autoconfig(_ emailAddress: String, sources: [Source] = Source.allCases, queryMX: Bool = true) async throws -> (config: ClientConfig, source: Source) {
        for source in sources {
            guard let config: ClientConfig = try? await autoconfig(emailAddress, source: source).config else { continue }
            return (config, source)
        }
        guard queryMX else {
            throw URLError(.fileDoesNotExist)
        }
        let records: [MXRecord] = try await DNSResolver.queryMX(emailAddress)
        guard let host: String = records.first?.host else {
            throw URLError(.unsupportedURL)
        }
        let domain: String = try await domain(host: host)
        return try await autoconfig(domain, sources: sources, queryMX: false)
    }

    /// Query a single autoconfig source using  a given email address.
    public func autoconfig(_ emailAddress: String, source: Source) async throws -> (config: ClientConfig, data: (Data, Data)) {
        let url: URL = try .autoconfig(emailAddress, source: source)
        let data: (Data, URLResponse) = try await data(from: url)
        switch (data.1 as? HTTPURLResponse)?.statusCode {
        case 200:
            let json: Data = try XMLToJSONParser(emailAddress, data: data.0).data
            let container: Container = try JSONDecoder().decode(Container.self, from: json)
            return (container.clientConfig, (json, data.0))
        case 404:
            throw URLError(.fileDoesNotExist)
        default:
            throw URLError(.unsupportedURL)
        }
    }

    private struct Container: Decodable {
        let clientConfig: ClientConfig
    }
}

extension URLSession {
    /// Derive domain name from a give host name using the [Public Suffix List.](https://publicsuffix.org)
    public func domain(host: String) async throws -> String {
        let suffixList: [String] = try await suffixList()
        let parser: DomainParser = try DomainParser(host: host, suffixList: suffixList)
        return parser.domain
    }

    func suffixList() async throws -> [String] {
        let data: (Data, URLResponse) = try await data(from: .suffixList)
        let suffixList: [String] = try SuffixListParser(data: data.0).suffixList
        return suffixList
    }
}

extension URLSession {
    func token(_ request: OAuth2.Request, code: String) async throws -> String {
        fatalError()
    }
}

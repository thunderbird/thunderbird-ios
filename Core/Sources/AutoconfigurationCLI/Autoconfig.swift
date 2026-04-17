import ArgumentParser
import Autoconfiguration
import Foundation

@main
struct Autoconfig: AsyncParsableCommand {
    @Argument(help: "Specify email address to query.")
    var emailAddress: String

    @Flag(name: .shortAndLong, help: "Save config files to working directory.")
    var save: Bool = false

    @Flag(name: .shortAndLong, help: "Open URLs; show saved files in Finder.")
    var open: Bool = false

    // MARK: AsyncParsableCommand
    func run() async throws {
        // Routine explodes the paths that `URLSession.autoconfig(_ emailAddress:)` follows
        // All sources are queried for printing/debugging purposes
        print("EMAIL ADDRESS: <\(emailAddress)>")
        print("")
        if !(try await query(emailAddress)) {
            // No configuration found for email address host; look for underlying MX host and retry
            print("Querying MX records for \((try? emailAddress.host) ?? emailAddress)…")
            let records: [MXRecord] = try await DNSResolver.queryMX(emailAddress)
            guard let host: String = records.first?.host else {
                throw URLError(.unsupportedURL)
            }
            print("Found host: \(host)")
            let domain: String = try await URLSession.shared.domain(host: host)
            print("Found domain: \(domain)")
            print("")
            try await query(emailAddress, domain: domain)
        }
        if open, save {
            Bundle.main.showExecutableInFinder()
        }
    }

    @discardableResult private func query(_ emailAddress: String, domain: String? = nil) async throws -> Bool {
        var found: Bool = false  // Keep track of findings while looping sources
        for source in Source.allCases {
            print("Querying the \(source) for \(domain ?? (try? emailAddress.host) ?? emailAddress)…")
            do {
                let autoconfig: (config: ClientConfig, data: (Data, Data)) = try await URLSession.shared.autoconfig(domain ?? emailAddress, source: source)
                print("Configuration found for \(domain ?? emailAddress):")
                print("")
                if let emailProvider: EmailProvider = autoconfig.config.emailProvider {
                    print("EMAIL PROVIDER:")
                    print("  Display name: \(emailProvider.displayName) (\(emailProvider.displayShortName))")
                    print("  Domain: \(emailProvider.domain)")
                    print("")
                    if !emailProvider.documentation.isEmpty {
                        print("  Documentation:")
                        for url in emailProvider.documentation {
                            print("    \(url.absoluteString)")
                        }
                        print("")
                    }
                    print("  Servers:")
                    for server in emailProvider.servers {
                        print("    [\(server.serverType)] \(server.hostname) \(server.port) \(server.socketType) \(server.authentication.joined(separator: "/"))")
                    }
                    print("")
                }
                if let oAuth2: OAuth2 = autoconfig.config.oAuth2 {
                    print("OAUTH2:")
                    print("  Issuer: \(oAuth2.issuer)")
                    print("  Scope: \(oAuth2.scope)")
                    print("")
                    print("  Auth URL:")
                    print("    \(oAuth2.authURL.absoluteString)")
                    print("")
                    print("  Token URL:")
                    print("    \(oAuth2.tokenURL.absoluteString)")
                    print("")
                }
                if let loginPage: URL = autoconfig.config.webMail?.loginPage {
                    print("WEB MAIL:")
                    print("  \(loginPage.absoluteString)")
                    print("")
                }
                if save {
                    try FileManager.default.save(emailAddress, data: autoconfig.data)
                }
                if open {
                    try? autoconfig.config.openWebMailLoginPage()
                    try? autoconfig.config.openDocumentation()
                }
                found = true
            } catch {
                print((error as? URLError)?.description ?? error.localizedDescription)
                print("")
            }
        }
        return found  // Returned value indicates whether retry needed
    }
}

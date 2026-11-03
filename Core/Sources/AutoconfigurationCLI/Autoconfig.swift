// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ArgumentParser
import Autoconfiguration
import Foundation

/// The `autoconfig` command-line tool: looks up and prints the mail server settings for an email address.
///
/// It follows the same path as `URLSession.autoconfig(_:sources:queryMX:)`, but expands it for debugging. Every
/// `Source` is queried and printed, rather than stopping at the first one that succeeds. If none has a configuration,
/// the domain of the first MX host is derived and every source is queried again for it.
///
/// ```
/// autoconfig user@example.com [--save] [--open]
/// ```
///
/// The command exits successfully even when no configuration is found; per-source errors are printed, not thrown.
@main
struct Autoconfig: AsyncParsableCommand {
    /// Email address, or bare domain, to look up.
    @Argument(help: "Specify email address to query.")
    var emailAddress: String

    /// Save each configuration found as `config.json` and `config.xml` in a folder named after ``emailAddress``.
    ///
    /// - Important: Files are saved next to the `autoconfig` executable, not in the working directory as the help
    ///   text says. When more than one source has a configuration, each save replaces the previous one, so only the
    ///   last source found (in `Source` order) is kept.
    @Flag(name: .shortAndLong, help: "Save config files to working directory.")
    var save: Bool = false

    /// Open each configuration's web mail login page and documentation links in the default browser.
    ///
    /// Combined with ``save``, also shows the executable's folder in Finder once all lookups finish. Does nothing on
    /// platforms without Cocoa.
    @Flag(name: .shortAndLong, help: "Open URLs; show saved files in Finder.")
    var open: Bool = false

    // MARK: AsyncParsableCommand
    /// Query every source for ``emailAddress``, falling back to the domain of its first MX host if none has a
    /// configuration.
    ///
    /// - Throws: `URLError(.unsupportedURL)` if the fallback finds no MX records, or a DNS or `URLSession.domain(host:)`
    ///   error from the fallback.
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

    /// Query every `Source` in order and print each configuration found, saving and opening it if requested.
    ///
    /// Errors from a source, including a failed save, are printed and the next source is tried.
    ///
    /// - Note: A failed save skips marking that source as found, so a save error alone can trigger the MX fallback.
    ///
    /// - Parameters:
    ///   - emailAddress: Email address being looked up; also names the save folder.
    ///   - domain: Domain to query in place of `emailAddress`'s host, used for the MX fallback. Placeholders such as
    ///     `%EMAILADDRESS%` are still filled from `emailAddress`.
    /// - Returns: `true` if at least one source returned a configuration (and saved it, when ``save`` is set).
    @discardableResult private func query(_ emailAddress: String, domain: String? = nil) async throws -> Bool {
        var found: Bool = false  // Keep track of findings while looping sources
        for source in Source.allCases {
            print("Querying the \(source) for \(domain ?? (try? emailAddress.host) ?? emailAddress)…")
            do {
                let autoconfig: (config: ClientConfig, data: (Data, Data)) = try await URLSession.shared.autoconfig(emailAddress, source: source, domain: domain)
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

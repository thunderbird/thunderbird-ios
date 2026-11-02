// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Autoconfiguration
import Foundation
import Testing

struct URLSessionTests {
    //Expect: Throw a `URLError`.
    //Case: When no source has a config for thunderbird.net and the MX fallback is disabled.
    @Test func autoconfigSources_throws_whenMXFallbackIsDisabledForThunderbirdNet() async throws {
        // Arrange
        let input = "username@thunderbird.net"

        // Act & Assert
        await #expect(throws: URLError.self) {
            try await URLSession.shared.autoconfig(input, queryMX: false)
        }
    }

    //Expect: Return a config with three servers.
    //Case: When using the default sources and MX fallback.
    @Test func autoconfigSources_returnsThreeServers_whenAddressIsThunderbirdNet() async throws {
        // Arrange
        let input = "username@thunderbird.net"
        let expected = 3

        // Act
        let actual = try await URLSession.shared.autoconfig(input).config.emailProvider?.servers.count

        // Assert
        #expect(actual == expected)
    }

    //Expect: Find the config through the MX fallback and report ISPDB as the source.
    //Case: When using the default sources and MX fallback.
    @Test func autoconfigSources_reportsISPDBSource_whenAddressIsThunderbirdNet() async throws {
        // Arrange
        let input = "username@thunderbird.net"
        let expected: Source = .ispDB

        // Act
        let actual = try await URLSession.shared.autoconfig(input).source

        // Assert
        #expect(actual == expected)
    }

    //Expect: Throw a `URLError`.
    //Case: When only the provider and well-known sources are queried, including after the MX fallback.
    @Test func autoconfigSources_throws_whenOnlyProviderSourcesAreQueriedForGmail() async throws {
        // Arrange
        let input = "user.name@gmail.com"

        // Act & Assert
        await #expect(throws: URLError.self) {
            try await URLSession.shared.autoconfig(input, sources: [.provider, .wellKnown])
        }
    }

    //Expect: Return a config with three servers.
    //Case: When using the default sources with the MX fallback disabled.
    @Test func autoconfigSources_returnsThreeServers_whenAddressIsGmailWithoutMXFallback() async throws {
        // Arrange
        let input = "user.name@gmail.com"
        let expected = 3

        // Act
        let actual = try await URLSession.shared.autoconfig(input, queryMX: false).config.emailProvider?.servers.count

        // Assert
        #expect(actual == expected)
    }

    //Expect: Find the config in ISPDB without needing the MX fallback.
    //Case: When using the default sources with the MX fallback disabled.
    @Test func autoconfigSources_reportsISPDBSource_whenAddressIsGmailWithoutMXFallback() async throws {
        // Arrange
        let input = "user.name@gmail.com"
        let expected: Source = .ispDB

        // Act
        let actual = try await URLSession.shared.autoconfig(input, queryMX: false).source

        // Assert
        #expect(actual == expected)
    }

    //Expect: Throw a `URLError`.
    //Case: When only ISPDB is queried and the MX fallback is disabled.
    @Test func autoconfigSources_throws_whenOnlyISPDBIsQueriedWithoutMXFallbackForFastmail() async throws {
        // Arrange
        let input = "user@fastmail.com"

        // Act & Assert
        await #expect(throws: URLError.self) {
            try await URLSession.shared.autoconfig(input, sources: [.ispDB], queryMX: false)
        }
    }

    //Expect: Return a config with three servers.
    //Case: When using the default sources and MX fallback.
    @Test func autoconfigSources_returnsThreeServers_whenAddressIsFastmail() async throws {
        // Arrange
        let input = "user@fastmail.com"
        let expected = 3

        // Act
        let actual = try await URLSession.shared.autoconfig(input).config.emailProvider?.servers.count

        // Assert
        #expect(actual == expected)
    }

    //Expect: Find the config at the provider's own `autoconfig` subdomain first.
    //Case: When using the default sources and MX fallback.
    @Test func autoconfigSources_reportsProviderSource_whenAddressIsFastmail() async throws {
        // Arrange
        let input = "user@fastmail.com"
        let expected: Source = .provider

        // Act
        let actual = try await URLSession.shared.autoconfig(input).source

        // Assert
        #expect(actual == expected)
    }

    //Expect: Throw a `URLError`.
    //Case: When only the provider and well-known sources are queried, including after the MX fallback.
    @Test func autoconfigSources_throws_whenOnlyProviderSourcesAreQueriedForAOL() async throws {
        // Arrange
        let input = "user123@aol.com"

        // Act & Assert
        await #expect(throws: URLError.self) {
            try await URLSession.shared.autoconfig(input, sources: [.provider, .wellKnown])
        }
    }

    //Expect: Return a config with three servers.
    //Case: When using the default sources and MX fallback.
    @Test func autoconfigSources_returnsThreeServers_whenAddressIsAOL() async throws {
        // Arrange
        let input = "user123@aol.com"
        let expected = 3

        // Act
        let actual = try await URLSession.shared.autoconfig(input).config.emailProvider?.servers.count

        // Assert
        #expect(actual == expected)
    }

    //Expect: Find the config in ISPDB after the provider sources fail.
    //Case: When using the default sources and MX fallback.
    @Test func autoconfigSources_reportsISPDBSource_whenAddressIsAOL() async throws {
        // Arrange
        let input = "user123@aol.com"
        let expected: Source = .ispDB

        // Act
        let actual = try await URLSession.shared.autoconfig(input).source

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the provider's display name.
    //Case: When fetching Gmail's config from ISPDB.
    @Test func autoconfigSource_decodesDisplayName_whenFetchingGmailFromISPDB() async throws {
        // Arrange
        let input = "user.name@gmail.com"
        let expected = "Google Mail"

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.displayName

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the provider's short display name.
    //Case: When fetching Gmail's config from ISPDB.
    @Test func autoconfigSource_decodesDisplayShortName_whenFetchingGmailFromISPDB() async throws {
        // Arrange
        let input = "user.name@gmail.com"
        let expected = "GMail"

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.displayShortName

        // Assert
        #expect(actual == expected)
    }

    //Expect: Collect 4 documentation links.
    //Case: When fetching Gmail's config from ISPDB.
    @Test func autoconfigSource_collectsDocumentationLinks_whenFetchingGmailFromISPDB() async throws {
        // Arrange
        let input = "user.name@gmail.com"
        let expected = 4

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.documentation.count

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the provider's primary domain.
    //Case: When fetching Gmail's config from ISPDB.
    @Test func autoconfigSource_decodesDomain_whenFetchingGmailFromISPDB() async throws {
        // Arrange
        let input = "user.name@gmail.com"
        let expected = "gmail.com"

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.domain

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode three servers.
    //Case: When fetching Gmail's config from ISPDB.
    @Test func autoconfigSource_decodesThreeServers_whenFetchingGmailFromISPDB() async throws {
        // Arrange
        let input = "user.name@gmail.com"
        let expected = 3

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.servers.count

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the first server's authentication methods, in order.
    //Case: When fetching Gmail's config from ISPDB.
    @Test func autoconfigSource_decodesFirstServerAuthentication_whenFetchingGmailFromISPDB() async throws {
        // Arrange
        let input = "user.name@gmail.com"
        let expected: [EmailProvider.Server.Authentication] = [
            .oAuth2,
            .passwordCleartext
        ]

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.servers.first?.authentication

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the first server's host name.
    //Case: When fetching Gmail's config from ISPDB.
    @Test func autoconfigSource_decodesFirstServerHostname_whenFetchingGmailFromISPDB() async throws {
        // Arrange
        let input = "user.name@gmail.com"
        let expected = "imap.gmail.com"

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.servers.first?.hostname

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the first server's port.
    //Case: When fetching Gmail's config from ISPDB.
    @Test func autoconfigSource_decodesFirstServerPort_whenFetchingGmailFromISPDB() async throws {
        // Arrange
        let input = "user.name@gmail.com"
        let expected = 993

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.servers.first?.port

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the first server as IMAP.
    //Case: When fetching Gmail's config from ISPDB.
    @Test func autoconfigSource_decodesFirstServerAsIMAP_whenFetchingGmailFromISPDB() async throws {
        // Arrange
        let input = "user.name@gmail.com"
        let expected: EmailProvider.Server.ServerType = .imap

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.servers.first?.serverType

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the first server's socket type as SSL.
    //Case: When fetching Gmail's config from ISPDB.
    @Test func autoconfigSource_decodesFirstServerSocketTypeAsSSL_whenFetchingGmailFromISPDB() async throws {
        // Arrange
        let input = "user.name@gmail.com"
        let expected: EmailProvider.Server.SocketType = .ssl

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.servers.first?.socketType

        // Assert
        #expect(actual == expected)
    }

    //Expect: Substitute the email address into the first server's username.
    //Case: When fetching Gmail's config from ISPDB.
    @Test func autoconfigSource_substitutesEmailAddressInUsername_whenFetchingGmailFromISPDB() async throws {
        // Arrange
        let input = "user.name@gmail.com"
        let expected = "user.name@gmail.com"

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.servers.first?.username

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the web mail login page.
    //Case: When fetching Gmail's config from ISPDB.
    @Test func autoconfigSource_decodesWebMailLoginPage_whenFetchingGmailFromISPDB() async throws {
        // Arrange
        let input = "user.name@gmail.com"
        let expected = "https://accounts.google.com/ServiceLogin?service=mail&continue=http://mail.google.com/mail/"

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.webMail?.loginPage.absoluteString

        // Assert
        #expect(actual == expected)
    }

    //Expect: Throw a `URLError`.
    //Case: When the provider's `autoconfig` subdomain has no config for Gmail.
    @Test func autoconfigSource_throws_whenFetchingGmailFromProvider() async throws {
        // Arrange
        let input = "user.name@gmail.com"

        // Act & Assert
        await #expect(throws: URLError.self) {
            try await URLSession.shared.autoconfig(input, source: .provider)
        }
    }

    //Expect: Throw a `URLError`.
    //Case: When the provider's `.well-known` path has no config for Gmail.
    @Test func autoconfigSource_throws_whenFetchingGmailFromWellKnown() async throws {
        // Arrange
        let input = "user.name@gmail.com"

        // Act & Assert
        await #expect(throws: URLError.self) {
            try await URLSession.shared.autoconfig(input, source: .wellKnown)
        }
    }

    //Expect: Decode the provider's display name.
    //Case: When fetching Fastmail's config from the provider's `autoconfig` subdomain.
    @Test func autoconfigSource_decodesDisplayName_whenFetchingFastmailFromProvider() async throws {
        // Arrange
        let input = "user@fastmail.com"
        let expected = "Fastmail"

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .provider).config.emailProvider?.displayName

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the provider's short display name.
    //Case: When fetching Fastmail's config from the provider's `autoconfig` subdomain.
    @Test func autoconfigSource_decodesDisplayShortName_whenFetchingFastmailFromProvider() async throws {
        // Arrange
        let input = "user@fastmail.com"
        let expected = "Fastmail"

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .provider).config.emailProvider?.displayShortName

        // Assert
        #expect(actual == expected)
    }

    //Expect: Collect 2 documentation links.
    //Case: When fetching Fastmail's config from the provider's `autoconfig` subdomain.
    @Test func autoconfigSource_collectsDocumentationLinks_whenFetchingFastmailFromProvider() async throws {
        // Arrange
        let input = "user@fastmail.com"
        let expected = 2

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .provider).config.emailProvider?.documentation.count

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the provider's primary domain.
    //Case: When fetching Fastmail's config from the provider's `autoconfig` subdomain.
    @Test func autoconfigSource_decodesDomain_whenFetchingFastmailFromProvider() async throws {
        // Arrange
        let input = "user@fastmail.com"
        let expected = "fastmail.com"

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .provider).config.emailProvider?.domain

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode three servers.
    //Case: When fetching Fastmail's config from the provider's `autoconfig` subdomain.
    @Test func autoconfigSource_decodesThreeServers_whenFetchingFastmailFromProvider() async throws {
        // Arrange
        let input = "user@fastmail.com"
        let expected = 3

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .provider).config.emailProvider?.servers.count

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the first server's only authentication method.
    //Case: When fetching Fastmail's config from the provider's `autoconfig` subdomain.
    @Test func autoconfigSource_decodesFirstServerAuthentication_whenFetchingFastmailFromProvider() async throws {
        // Arrange
        let input = "user@fastmail.com"
        let expected: [EmailProvider.Server.Authentication] = [
            .oAuth2
        ]

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .provider).config.emailProvider?.servers.first?.authentication

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the first server's host name.
    //Case: When fetching Fastmail's config from the provider's `autoconfig` subdomain.
    @Test func autoconfigSource_decodesFirstServerHostname_whenFetchingFastmailFromProvider() async throws {
        // Arrange
        let input = "user@fastmail.com"
        let expected = "imap.fastmail.com"

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .provider).config.emailProvider?.servers.first?.hostname

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the first server's port.
    //Case: When fetching Fastmail's config from the provider's `autoconfig` subdomain.
    @Test func autoconfigSource_decodesFirstServerPort_whenFetchingFastmailFromProvider() async throws {
        // Arrange
        let input = "user@fastmail.com"
        let expected = 993

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .provider).config.emailProvider?.servers.first?.port

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the first server as IMAP.
    //Case: When fetching Fastmail's config from the provider's `autoconfig` subdomain.
    @Test func autoconfigSource_decodesFirstServerAsIMAP_whenFetchingFastmailFromProvider() async throws {
        // Arrange
        let input = "user@fastmail.com"
        let expected: EmailProvider.Server.ServerType = .imap

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .provider).config.emailProvider?.servers.first?.serverType

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the first server's socket type as SSL.
    //Case: When fetching Fastmail's config from the provider's `autoconfig` subdomain.
    @Test func autoconfigSource_decodesFirstServerSocketTypeAsSSL_whenFetchingFastmailFromProvider() async throws {
        // Arrange
        let input = "user@fastmail.com"
        let expected: EmailProvider.Server.SocketType = .ssl

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .provider).config.emailProvider?.servers.first?.socketType

        // Assert
        #expect(actual == expected)
    }

    //Expect: Substitute the email address into the first server's username.
    //Case: When fetching Fastmail's config from the provider's `autoconfig` subdomain.
    @Test func autoconfigSource_substitutesEmailAddressInUsername_whenFetchingFastmailFromProvider() async throws {
        // Arrange
        let input = "user@fastmail.com"
        let expected = "user@fastmail.com"

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .provider).config.emailProvider?.servers.first?.username

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the web mail login page, with placeholders substituted.
    //Case: When fetching Fastmail's config from the provider's `autoconfig` subdomain.
    @Test func autoconfigSource_decodesWebMailLoginPage_whenFetchingFastmailFromProvider() async throws {
        // Arrange
        let input = "user@fastmail.com"
        let expected = "https://app.fastmail.com/login/?domain=fastmail.com"

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .provider).config.webMail?.loginPage.absoluteString

        // Assert
        #expect(actual == expected)
    }

    //Expect: Throw a `URLError`.
    //Case: When the provider's `.well-known` path has no config for Fastmail.
    @Test func autoconfigSource_throws_whenFetchingFastmailFromWellKnown() async throws {
        // Arrange
        let input = "user@fastmail.com"

        // Act & Assert
        await #expect(throws: URLError.self) {
            try await URLSession.shared.autoconfig(input, source: .wellKnown)
        }
    }

    //Expect: Throw a `URLError`.
    //Case: When ISPDB has no config for Fastmail.
    @Test func autoconfigSource_throws_whenFetchingFastmailFromISPDB() async throws {
        // Arrange
        let input = "user@fastmail.com"

        // Act & Assert
        await #expect(throws: URLError.self) {
            try await URLSession.shared.autoconfig(input, source: .ispDB)
        }
    }

    //Expect: Decode the provider's display name.
    //Case: When fetching AOL's config from ISPDB.
    @Test func autoconfigSource_decodesDisplayName_whenFetchingAOLFromISPDB() async throws {
        // Arrange
        let input = "user123@aol.com"
        let expected = "AOL Mail"

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.displayName

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the provider's short display name.
    //Case: When fetching AOL's config from ISPDB.
    @Test func autoconfigSource_decodesDisplayShortName_whenFetchingAOLFromISPDB() async throws {
        // Arrange
        let input = "user123@aol.com"
        let expected = "AOL"

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.displayShortName

        // Assert
        #expect(actual == expected)
    }

    //Expect: Collect 1 documentation link.
    //Case: When fetching AOL's config from ISPDB.
    @Test func autoconfigSource_collectsDocumentationLinks_whenFetchingAOLFromISPDB() async throws {
        // Arrange
        let input = "user123@aol.com"
        let expected = 1

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.documentation.count

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the provider's primary domain.
    //Case: When fetching AOL's config from ISPDB.
    @Test func autoconfigSource_decodesDomain_whenFetchingAOLFromISPDB() async throws {
        // Arrange
        let input = "user123@aol.com"
        let expected = "aol.com"

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.domain

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode three servers.
    //Case: When fetching AOL's config from ISPDB.
    @Test func autoconfigSource_decodesThreeServers_whenFetchingAOLFromISPDB() async throws {
        // Arrange
        let input = "user123@aol.com"
        let expected = 3

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.servers.count

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the first server's authentication methods, in order.
    //Case: When fetching AOL's config from ISPDB.
    @Test func autoconfigSource_decodesFirstServerAuthentication_whenFetchingAOLFromISPDB() async throws {
        // Arrange
        let input = "user123@aol.com"
        let expected: [EmailProvider.Server.Authentication] = [
            .oAuth2,
            .passwordCleartext
        ]

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.servers.first?.authentication

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the first server's host name.
    //Case: When fetching AOL's config from ISPDB.
    @Test func autoconfigSource_decodesFirstServerHostname_whenFetchingAOLFromISPDB() async throws {
        // Arrange
        let input = "user123@aol.com"
        let expected = "imap.aol.com"

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.servers.first?.hostname

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the first server's port.
    //Case: When fetching AOL's config from ISPDB.
    @Test func autoconfigSource_decodesFirstServerPort_whenFetchingAOLFromISPDB() async throws {
        // Arrange
        let input = "user123@aol.com"
        let expected = 993

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.servers.first?.port

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the first server as IMAP.
    //Case: When fetching AOL's config from ISPDB.
    @Test func autoconfigSource_decodesFirstServerAsIMAP_whenFetchingAOLFromISPDB() async throws {
        // Arrange
        let input = "user123@aol.com"
        let expected: EmailProvider.Server.ServerType = .imap

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.servers.first?.serverType

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the first server's socket type as SSL.
    //Case: When fetching AOL's config from ISPDB.
    @Test func autoconfigSource_decodesFirstServerSocketTypeAsSSL_whenFetchingAOLFromISPDB() async throws {
        // Arrange
        let input = "user123@aol.com"
        let expected: EmailProvider.Server.SocketType = .ssl

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.servers.first?.socketType

        // Assert
        #expect(actual == expected)
    }

    //Expect: Substitute the email address into the first server's username.
    //Case: When fetching AOL's config from ISPDB.
    @Test func autoconfigSource_substitutesEmailAddressInUsername_whenFetchingAOLFromISPDB() async throws {
        // Arrange
        let input = "user123@aol.com"
        let expected = "user123@aol.com"

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.emailProvider?.servers.first?.username

        // Assert
        #expect(actual == expected)
    }

    //Expect: Decode the web mail login page.
    //Case: When fetching AOL's config from ISPDB.
    @Test func autoconfigSource_decodesWebMailLoginPage_whenFetchingAOLFromISPDB() async throws {
        // Arrange
        let input = "user123@aol.com"
        let expected = "https://mail.aol.com/"

        // Act
        let actual = try await URLSession.shared.autoconfig(input, source: .ispDB).config.webMail?.loginPage.absoluteString

        // Assert
        #expect(actual == expected)
    }

    //Expect: Throw a `URLError`.
    //Case: When the provider's `autoconfig` subdomain has no config for AOL.
    @Test func autoconfigSource_throws_whenFetchingAOLFromProvider() async throws {
        // Arrange
        let input = "user123@aol.com"

        // Act & Assert
        await #expect(throws: URLError.self) {
            try await URLSession.shared.autoconfig(input, source: .provider)
        }
    }

    //Expect: Throw a `URLError`.
    //Case: When the provider's `.well-known` path has no config for AOL.
    @Test func autoconfigSource_throws_whenFetchingAOLFromWellKnown() async throws {
        // Arrange
        let input = "user123@aol.com"

        // Act & Assert
        await #expect(throws: URLError.self) {
            try await URLSession.shared.autoconfig(input, source: .wellKnown)
        }
    }
}

extension URLSessionTests {
    //Expect: Return the registrable domain of the host.
    //Case: When the host is a subdomain under a single-label suffix.
    @Test func domain_returnsRegistrableDomain_whenHostIsSubdomain() async throws {
        // Arrange
        let input = "smtp.example.com"
        let expected = "example.com"

        // Act
        let actual = try await URLSession.shared.domain(host: input)

        // Assert
        #expect(actual == expected)
    }

    //Expect: Throw a `URLError`.
    //Case: When the host doesn't end with any listed public suffix.
    @Test func domain_throws_whenHostHasNoListedSuffix() async throws {
        // Arrange
        let input = "host.example"

        // Act & Assert
        await #expect(throws: URLError.self) {
            try await URLSession.shared.domain(host: input)
        }
    }

    //Expect: Download and parse more than 10,000 suffix entries.
    //Case: When fetching the live Public Suffix List.
    @Test func suffixList_returnsMoreThan10000Suffixes_whenFetchingLiveList() async throws {
        // Act
        let actual = try await URLSession.shared.suffixList().count

        // Assert
        #expect(actual > 10000)
    }
}

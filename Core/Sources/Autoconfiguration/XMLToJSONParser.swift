import Foundation

// Translate client config XML into JSON
class XMLToJSONParser: NSObject, XMLParserDelegate {
    private(set) var emailAddress: String!
    private(set) var dictionary: [String: Any] = [:]

    var data: Data {
        get throws {
            try JSONSerialization.data(
                withJSONObject: dictionary,
                options: [
                    .withoutEscapingSlashes,
                    .prettyPrinted,
                    .sortedKeys
                ])
        }
    }

    init(_ emailAddress: String, data: Data) {
        parser = XMLParser(data: data)
        super.init()
        self.emailAddress = emailAddress
        parser.delegate = self
        parser.parse()
    }

    private let parser: XMLParser
    private var element: (name: String, value: String?)?
    private var emailProvider: [String: Any]?
    private var oAuth2: [String: Any]?
    private var webMail: [String: Any]?
    private var server: [String: Any]?

    private enum Key: CodingKey {
        case clientConfig
        case emailProvider
        case displayName, displayShortName, domain
        case servers, incomingServer, outgoingServer
        case authentication, hostname, port, serverType, socketType, type, username
        case documentation, instruction, url
        case oAuth2, authURL, issuer, scope, tokenURL
        case webMail, loginPage
    }

    // MARK: XMLParserDelegate
    func parserDidStartDocument(_ parser: XMLParser) {}

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        switch Key(stringValue: elementName) {
        case .clientConfig:
            dictionary[Key.clientConfig.stringValue] = [:]
        case .emailProvider:
            emailProvider = [
                Key.servers.stringValue: [],
                Key.documentation.stringValue: []
            ]
        case .displayName, .displayShortName, .domain:
            element = (elementName, nil)
        case .incomingServer, .outgoingServer:
            server = [
                Key.authentication.stringValue: [],
                Key.serverType.stringValue: (attributeDict[Key.type.stringValue] ?? "")  // Convert server `type` attribute to dictionary key/value
            ]
        case .authentication, .hostname, .port, .socketType, .username:
            element = (elementName, nil)
        case .documentation, .instruction:
            if var documentation: [String] = emailProvider?[Key.documentation.stringValue] as? [String],
                let url: String = attributeDict[Key.url.stringValue]
            {
                documentation.append(url)
                emailProvider?[Key.documentation.stringValue] = documentation
            }
        case .oAuth2:
            oAuth2 = [:]
        case .authURL, .issuer, .scope, .tokenURL:
            element = (elementName, nil)
        case .loginPage:
            if let loginPage: String = attributeDict[Key.url.stringValue] {
                webMail = [
                    Key.loginPage.stringValue: loginPage.applying(emailAddress)  // Convert login page `url` attribute to dictionary key/value
                ]
            }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let string: String = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !string.isEmpty else { return }
        element?.value = string.applying(emailAddress)
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        switch Key(stringValue: elementName) {
        case .emailProvider:
            if var clientConfig: [String: Any] = dictionary[Key.clientConfig.stringValue] as? [String: Any],
                let emailProvider
            {
                clientConfig[Key.emailProvider.stringValue] = emailProvider
                dictionary[Key.clientConfig.stringValue] = clientConfig
            }
            emailProvider = nil
        case .displayName, .displayShortName, .domain:
            if elementName == Key.domain.stringValue, emailProvider?[Key.domain.stringValue] != nil {
                break  // Keep first domain only
            }
            if let name: String = element?.name, let value: String = element?.value {
                emailProvider?[name] = value
            }
            element = nil
        case .incomingServer, .outgoingServer:
            if var servers: [[String: Any]] = emailProvider?[Key.servers.stringValue] as? [[String: Any]],
                let server
            {
                servers.append(server)
                emailProvider?[Key.servers.stringValue] = servers
            }
            server = nil
        case .authentication:
            if let name: String = element?.name, let value: String = element?.value,
                var authentication = server?[name] as? [Any]
            {
                authentication.append(value)
                server?[name] = authentication
            }
            element = nil
        case .hostname, .port, .socketType, .username:
            if let name: String = element?.name, let value: String = element?.value {
                server?[name] = elementName == Key.port.stringValue ? Int(value) : value
            }
            element = nil
        case .oAuth2:
            if var clientConfig: [String: Any] = dictionary[Key.clientConfig.stringValue] as? [String: Any],
                let oAuth2
            {
                clientConfig[Key.oAuth2.stringValue] = oAuth2
                dictionary[Key.clientConfig.stringValue] = clientConfig
            }
            oAuth2 = nil
        case .authURL, .issuer, .scope, .tokenURL:
            if let name: String = element?.name, let value: String = element?.value {
                oAuth2?[name] = value
            }
            element = nil
        case .webMail:
            if var clientConfig: [String: Any] = dictionary[Key.clientConfig.stringValue] as? [String: Any],
                let webMail
            {
                clientConfig[Key.webMail.stringValue] = webMail
                dictionary[Key.clientConfig.stringValue] = clientConfig
            }
            webMail = nil
        default:
            break
        }
    }

    func parserDidEndDocument(_ parser: XMLParser) {}
}

private extension String {
    func applying(_ emailAddress: Self) -> Self {
        var string: Self = replacingOccurrences(of: "%EMAILADDRESS%", with: emailAddress)
        string = string.replacingOccurrences(of: "%EMAILLOCALPART%", with: (try? emailAddress.local) ?? "")
        string = string.replacingOccurrences(of: "%EMAILDOMAIN%", with: (try? emailAddress.host) ?? "")
        return string
    }
}

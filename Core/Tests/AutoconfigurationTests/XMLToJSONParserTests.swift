@testable import Autoconfiguration
import Foundation
import Testing

struct XMLToJSONParserTests {
    @Test func dictionary() {
        let fastmail: [String: Any] = XMLToJSONParser("user@fastmail.com", data: fastmail).dictionary
        #expect((fastmail["clientConfig"] as? [String: Any])?.keys.count == 2)
        let freenet: [String: Any] = XMLToJSONParser("user@freenet.de", data: freenet).dictionary
        #expect((freenet["clientConfig"] as? [String: Any])?.keys.count == 1)
        let gmail: [String: Any] = XMLToJSONParser("user.name@gmail.com", data: gmail).dictionary
        #expect((gmail["clientConfig"] as? [String: Any])?.keys.count == 3)
    }

    @Test func data() throws {
        #expect(try XMLToJSONParser("user@fastmail.com", data: fastmail).data.count == 1246)
        #expect(try XMLToJSONParser("user@freenet.de", data: freenet).data.count == 2059)
        #expect(try XMLToJSONParser("user.name@gmail.com", data: gmail).data.count == 1874)
    }
}

private let fastmail: Data = """
    <?xml version="1.0" encoding="UTF-8"?>

    <clientConfig version="1.1">
      <emailProvider id="MessagingEngine">
        <domain>fastmail.com</domain>
        <displayName>Fastmail</displayName>
        <displayShortName>Fastmail</displayShortName>
        <incomingServer type="imap">
          <hostname>imap.fastmail.com</hostname>
          <port>993</port>
          <socketType>SSL</socketType>
          <authentication>OAuth2</authentication>
          <username>%EMAILADDRESS%</username>
        </incomingServer>
        <incomingServer type="pop3">
          <hostname>pop.fastmail.com</hostname>
          <port>995</port>
          <socketType>SSL</socketType>
          <authentication>OAuth2</authentication>
          <username>%EMAILADDRESS%</username>
        </incomingServer>
        <outgoingServer type="smtp">
          <hostname>smtp.fastmail.com</hostname>
          <port>465</port>
          <socketType>SSL</socketType>
          <authentication>OAuth2</authentication>
          <username>%EMAILADDRESS%</username>
        </outgoingServer>
        <instruction url="https://www.fastmail.help/hc/en-us/articles/1500000278342">
          <descr lang="en">Server Names and Ports</descr>
        </instruction>
        <instruction url="https://www.fastmail.help/hc/en-us/articles/360058753054">
          <descr lang="en">Using Fastmail with Mozilla Thunderbird</descr>
        </instruction>
      </emailProvider>
      <webMail>
        <loginPage url="https://app.fastmail.com/login/?domain=%EMAILDOMAIN%" />
      </webMail>
    </clientConfig>
    """.data(using: .utf8)!

private let freenet: Data = """
    <?xml version="1.0" encoding="UTF-8"?>

    <clientConfig version="1.1">
      <emailProvider id="freenet.de">
        <domain>freenet.de</domain>
        <displayName>Freenet Mail</displayName>
        <displayShortName>Freenet</displayShortName>
        <incomingServer type="imap">
          <hostname>imap.freenet.de</hostname>
          <port>993</port>
          <socketType>SSL</socketType>
          <authentication>password-encrypted</authentication>
          <username>%EMAILADDRESS%</username>
        </incomingServer>
        <incomingServer type="imap">
          <hostname>imap.freenet.de</hostname>
          <port>143</port>
          <socketType>STARTTLS</socketType>
          <authentication>password-encrypted</authentication>
          <username>%EMAILADDRESS%</username>
        </incomingServer>
        <incomingServer type="pop3">
          <hostname>pop.freenet.de</hostname>
          <port>995</port>
          <socketType>SSL</socketType>
          <authentication>password-cleartext</authentication>
          <username>%EMAILADDRESS%</username>
        </incomingServer>
        <incomingServer type="pop3">
          <hostname>pop.freenet.de</hostname>
          <port>110</port>
          <socketType>STARTTLS</socketType>
          <authentication>password-cleartext</authentication>
          <username>%EMAILADDRESS%</username>
        </incomingServer>
        <outgoingServer type="smtp">
          <hostname>smtp.freenet.de</hostname>
          <port>465</port>
          <socketType>SSL</socketType>
          <authentication>password-encrypted</authentication>
          <username>%EMAILADDRESS%</username>
        </outgoingServer>
        <outgoingServer type="smtp">
          <hostname>smtp.freenet.de</hostname>
          <port>587</port>
          <socketType>STARTTLS</socketType>
          <authentication>password-encrypted</authentication>
          <username>%EMAILADDRESS%</username>
        </outgoingServer>
        <documentation url="http://kundenservice.freenet.de/hilfe/email/programme/config/index.html">
          <descr lang="de">Allgemeine Beschreibung der Einstellungen</descr>
          <descr lang="en">Generic settings page</descr>
        </documentation>
        <documentation url="http://kundenservice.freenet.de/hilfe/email/programme/config/thunderbird/imap-thunderbird/imap/index.html">
          <descr lang="de">TB 2.0 IMAP-Einstellungen</descr>
          <descr lang="en">TB 2.0 IMAP settings</descr>
        </documentation>
      </emailProvider>
    </clientConfig>
    """.data(using: .utf8)!

private let gmail: Data = """
    <clientConfig version="1.1">
      <emailProvider id="googlemail.com">
        <domain>gmail.com</domain>
        <domain>googlemail.com</domain>
        <!-- MX, for Google Apps -->
        <domain>google.com</domain>

        <displayName>Google Mail</displayName>
        <displayShortName>GMail</displayShortName>

        <incomingServer type="imap">
          <hostname>imap.gmail.com</hostname>
          <port>993</port>
          <socketType>SSL</socketType>
          <username>%EMAILADDRESS%</username>
          <authentication>OAuth2</authentication>
          <authentication>password-cleartext</authentication>
        </incomingServer>
        <incomingServer type="pop3">
          <hostname>pop.gmail.com</hostname>
          <port>995</port>
          <socketType>SSL</socketType>
          <username>%EMAILADDRESS%</username>
          <authentication>OAuth2</authentication>
          <authentication>password-cleartext</authentication>
          <pop3>
            <leaveMessagesOnServer>true</leaveMessagesOnServer>
          </pop3>
        </incomingServer>
        <outgoingServer type="smtp">
          <hostname>smtp.gmail.com</hostname>
          <port>465</port>
          <socketType>SSL</socketType>
          <username>%EMAILADDRESS%</username>
          <authentication>OAuth2</authentication>
          <authentication>password-cleartext</authentication>
        </outgoingServer>

        <documentation url="http://mail.google.com/support/bin/answer.py?answer=13273">
          <descr>How to enable IMAP/POP3 in GMail</descr>
        </documentation>
        <documentation url="http://mail.google.com/support/bin/topic.py?topic=12806">
          <descr>How to configure email clients for IMAP</descr>
        </documentation>
        <documentation url="http://mail.google.com/support/bin/topic.py?topic=12805">
          <descr>How to configure email clients for POP3</descr>
        </documentation>
        <documentation url="http://mail.google.com/support/bin/answer.py?answer=86399">
          <descr>How to configure TB 2.0 for POP3</descr>
        </documentation>
      </emailProvider>

      <oAuth2>
        <issuer>accounts.google.com</issuer>
        <!-- https://developers.google.com/identity/protocols/oauth2/scopes -->
        <scope>https://mail.google.com/ https://www.googleapis.com/auth/contacts https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/carddav</scope>
        <authURL>https://accounts.google.com/o/oauth2/auth</authURL>
        <tokenURL>https://www.googleapis.com/oauth2/v3/token</tokenURL>
      </oAuth2>

      <enable visiturl="https://mail.google.com/mail/?ui=2&amp;shva=1#settings/fwdandpop">
        <instruction>You need to enable IMAP access</instruction>
      </enable>

      <webMail>
        <loginPage url="https://accounts.google.com/ServiceLogin?service=mail&amp;continue=http://mail.google.com/mail/"/>
        <loginPageInfo url="https://accounts.google.com/ServiceLogin?service=mail&amp;continue=http://mail.google.com/mail/">
          <username>%EMAILADDRESS%</username>
          <usernameField id="Email"/>
          <passwordField id="Passwd"/>
          <loginButton id="signIn"/>
        </loginPageInfo>
      </webMail>

    </clientConfig>
    """.data(using: .utf8)!

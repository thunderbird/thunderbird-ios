# Core Libraries

`Core` package contains a suite of libraries that power [Thunderbird iOS.](https://github.com/thunderbird/thunderbird-ios) `Core` libraries are designed to share similar [async/await](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0296-async-await.md) interfaces and/or to seamlessly extend `Foundation` frameworks and types, e.g., adding [JMAP](#jmap)-specific `URLSession` data tasks.

* [`Autoconfiguration`](#autoconfig)
* [`EmailAddress`](#email)
* [`IMAP` and `SMTP`](#imap-smtp)
* [`JMAP`](#jmap)
* [`MIME`](#mime)

## `Autoconfiguration` <a name="autoconfig"></a>

[Thunderbird Autoconfiguration](https://wiki.mozilla.org/Thunderbird:Autoconfiguration), often just "autoconfig," is an XML syndication format where email service providers advertise public mail server settings.

`Autoconfigruation` library is designed to support email account setup in its parent project, [Thunderbird iOS](https://github.com/thunderbird/thunderbird-ios), via `URLSession` data task:

```swift
import Autoconfiguration
import Foundation

let example: (config: ClientConfig, source: Source) = try await URLSession.shared.autoconfig("user@example.com")
```

Taking the default arguments, the above returns mail server settings for almost every email address in existence. Here's how it works:

1. Query all sources using the domain name from the given email address. If more than one client configuration is found, prefer the provider-provided configuration over the [Thunderbird "ISPDB" autoconfig database.](https://github.com/thunderbird/autoconfig)
2. If no configuration is found, the given email address is probably using a custom domain. Query [MX records](https://wikipedia.org/wiki/MX_record) for an underlying domain name, then re-query all sources using the underlying domain name.

MX records can be queried directly:

```swift
import Autoconfiguration

let records: [MXRecord] = try await DNSResolver.queryMX("example.com")
```

#### Domain Parsing

`Autoconfiguration` library uses the [Public Suffix List](https://publicsuffix.org) to parse domains from DNS host names:

```swift
import Autoconfiguration
import Foundation

let domain: String = try await URLSession.shared.domain(host: "smtp01.mail.example.com")
print(domain)  // example.com
```

#### Autodiscover(y)

`Autoconfiguration` supports [DNS service autodiscovery]((https://wikipedia.org/wiki/SRV_record)) for protocols like [JMAP](https://jmap.io) that don't use autoconfig:

```swift
import Autoconfiguration

let records: [SRVRecord] = try await DNSResolver.querySRV("name@example.com")
```

[Autodiscover for Exchange](https://learn.microsoft.com/en-us/exchange/client-developer/exchange-web-services/autodiscover-for-exchange) is not supported at this time. Local and [MDM](https://support.apple.com/guide/deployment/welcome/web) configurations are not supported yet.

`Autoconfiguration` library depends on the [Swift Asynchronous DNS Resolver.](https://github.com/apple/swift-async-dns-resolver)

#### Command-line interface

`autoconfig` is a bundled CLI demo of `Autoconfiguration` library:

```zsh
./autoconfig name@example.com -so
```

Email address is a required argument, plus two flags:

* `--save`: Save original config XML and JSON files to app working directory.
* `--open`: Open all config URLs in a browser; if saving, show files in Finder.

## `EmailAddress` <a name="email"></a>

An [email address](https://wikipedia.org/wiki/Email_address) is a string with parts, formatted one of two specific ways: `Example Name <name@example.com>` or just `name@example.com`.

`EmailAddress` provides a shared model with conveniences for encoding and decoding addresses, as well as accessing the component parts:

```swift
import EmailAddress

let example: EmailAddress = "Example Name <name@example.com>"
print(example)  // Example Name <name@example.com>
print(example.value)  // name@example.com
print(example.label)  // Example Name
```

## `IMAP` and `SMTP` <a name="imap-smtp"></a>

Thunderbird supports sending and receiving email for most email providers through [Internet Message Access Protocol](https://wikipedia.org/wiki/Internet_Message_Access_Protocol) (IMAP) and [Simple Mail Transfer Protocol](https://wikipedia.org/wiki/Simple_Mail_Transfer_Protocol) (SMTP).

Both protocols use [TCP](https://wikipedia.org/wiki/Transmission_Control_Protocol) for transport, not HTTP; both libraries depend on [SwiftNIO.](https://opensource.apple.com/projects/swiftnio)

### `IMAP`

`IMAP` supports IMAP4rev1. The underlying implementation glues [NIOIMAP](https://github.com/apple/swift-nio-imap) models and networking into a coherent async/await interface.

For illustration, here's a common IMAP command sequence. Configure `IMAPClient` with `Server`, connect and authenticate:

```swift
import IMAP
import MIME

let client: IMAPClient = IMAPClient(Server(hostname: "imap.example.com"))
try await client.connect()
try await client.authenticate(.plain("name@example.com", password: "fAK3-PASs-w0rD"))
```

For the authenticated client, list mailboxes and select inbox:

```swift
let mailboxes: [Mailbox] = try await client.list().map { $0.0 }  // List mailboxes
guard let inbox: Mailbox = mailboxes.filter({ $0.path.name.isInbox }).first else {
    throw IMAPError.unexpectedResponse("Inbox not found")
}  // Find inbox in mailbox list
try await client.select(mailbox: inbox)  // Select inbox
let status = try await client.status(mailbox: inbox)
print(status.messageCount)  // 327
print(status.unseenCount)  // 5
```

Fetch all headers and envelope metadata for selected mailbox:

```swift
let messages: MessageSet = try await client.fetch()
for sequenceNumber in messages.keys.sorted().reversed() {
    print(messages[sequenceNumber]?.envelope.subject)  // Decoded email subject line
    print(messages[sequenceNumber]?.envelope.sender)  // sender@example.com
}
```

Fetch complete email message for highest inbox sequence number (newest message):

```swift
guard let sequenceNumber: SequenceNumber = messages.keys.sorted().reversed().first else {
    throw IMAPError.unexpectedResponse("Message not found")
}
let message: Message = try await client.fetch(sequenceNumber)
print(message.envelope.subject)  // Decoded email subject line
print(message.envelope.sender)  // sender@example.com
print(message.body)  // Decoded MIME parts, ready for display or additional assembly
```

Log out and disconnect:

```swift
try await client.logout()
try? client.disconnect()  // BYE
```

#### Idle

`IMAP` leverages [NIOIMAP](https://github.com/apple/swift-nio-imap) support for [IMAP4 `IDLE`.](https://www.rfc-editor.org/rfc/rfc2177)

For the authenticated client with inbox still selected, idle connection and handle inbox events "pushed" from server:

```swift
do {
    try client.isSupported(.idle)
    let idleEvents: AsyncStream<IdleEvent> = try await client.idle()
} catch {
    switch error {
    case IMAPError.capabilityNotSupported: break
    default: throw error
    }
}
try await client.done()  // Stop idling
```

Note: NIOIMAP keeps idling connection alive automatically; manual `NOOP` issued while idling throws.

#### Incomplete IMAP4 Support

Thunderbird intends to support every flavor of IMAP under the sun, as implemented. Building on top of NIOIMAP, `IMAP` library follows the same pragmatic approach, having a single implementation of each IMAP command or concept, with "fuzzy" handling for server implementation/configuration idiosyncrasies.

IMAP commands were implemented in practical order, i.e., fetching messages requires a selected mailbox. Selecting a mailbox requires an authenticated server connection, and so on. A few commands have not been implemented yet:

* [x] ~~`AUTHENTICATE`: Authenticate IMAP connection with OAuth using [SASL](https://en.wikipedia.org/wiki/Simple_Authentication_and_Security_Layer); preferred over `LOGIN` using app password.~~
* [ ] `APPEND`: Add a message to a mailbox; used primarily to save new message drafts on server.
* [ ] `SEARCH`: Search a mailbox on the server using structured queries.

`IMAP` library uses in-package [`MIME`](#mime) library for decoding and [Swift NIOIMAP](https://github.com/apple/swift-nio-imap) for IMAP commands, models and transport.

### `SMTP`

`SMTP` implementation is based on `NIOSMTP` example project included in the [SwiftNIO examples repository.](https://github.com/apple/swift-nio-examples)

Configure `SMTPClient` with a `Server`; send one or more emails through the same server:

```swift
import Foundation
import MIME
import SMTP

try await SMTPClient(Server(
    hostname: "smtp.mail.example.com",
    username: "username",
    password: "fake-appp-pass-word"
)).send(Email(
    sender: "sender@example.com",
    recipients: [
        "recipient@example.com"
    ],
    subject: "Example email subject",
    body: try! Body(parts: [
        Part(
            data: "Email body contents were made of plain, ASCII text at first.".data(using: .ascii)!,
            contentType: .text(.plain, .ascii)
        )
    ])
))
```

`SMTP` library uses in-package [`MIME`](#mime) library for encoding and [SwiftNIO](https://github.com/apple/swift-nio) for transport.

## `JMAP` <a name="jmap"></a>

[JSON Meta Application Protocol](https://jmap.io) (JMAP)) is a modern, API-based approach to email that uses standard HTTP requests and responses with JSON serialization for transit.

`JMAP` library is a client implementation of both [JMAP core](https://jmap.io/spec/rfc8620) and [JMAP mail](https://jmap.io/spec/rfc8621) protocols, with functionality tailored for use in [Thunderbird iOS.](https://github.com/thunderbird/thunderbird-ios)

JMAP support is early and experimental.

## `MIME` <a name="mime"></a>

[Multipurpose Internet Mail Extensions](https://wikipedia.org/wiki/MIME) (MIME), colloquially "multipart data," extends basic, ASCII-text email to support text with various character encodings and binary objects like images, audio and video.

`MIME` library is a multipart message encoder and decoder. It's useful for the following purposes:

* Decoding IMAP- or POP-delivered email messages
* Encoding email messages for SMTP sending
* Encoding attachments for JMAP uploading

Modeled types adopt Swift [`RawRepresentable`](https://developer.apple.com/documentation/swift/RawRepresentable) to serialize and deserialize raw ASCII data representations. Each `Part` consists of a blob of ASCII [`Data`](https://developer.apple.com/documentation/foundation/data) and headers describing the data:

* `ContentType` specifies what the data blob _is_, e.g., `image/png` or `text/html; charset="utf-8"`.
* `ContentTransferEncoding` labels how the data is ASCII-encoded for transit, typically [base64](https://wikipedia.org/wiki/Base64) or [quoted-printable](https://wikipedia.org/wiki/Quoted-printable).
* `ContentDisposition` suggests whether the decoded data blob should appear inline as part of the message body or linked as an attachment.

Each `Part` can, itself, be multipart, allowing content to be grouped and nested. Multipart content types include a `Boundary` of 1-70 ASCII characters used to join and separate individual parts.

Parts roll up to a special top-level part, `Body`, which is parsed like any `Part`, but only accepts possible message body types, text or multipart. Decode `Body` from raw email message source:

```swift
import Foundation
import MIME

guard let url: URL = Bundle.module.url(forResource: "email-example", withExtension: "eml") else {
    throw URLError(.fileDoesNotExist)
}
let data: Data = try Data(contentsOf: url)
let body: Body = try Body(data)
print(body.contentType)  // multipart/alternative; boundary="_----------=_176171960423967"
print(body.contentTransferEncoding)  // 8bit
print(body.parts.count)  // 2
```

`Body` drops the `ContentDisposition` header and includes the MIME version header when encoded. Prepend the required SMTP headers and send:

```swift
guard let string: String = String(data: body.rawValue, encoding: .ascii) else {
    throw MIMEError.dataNotDecoded(body.rawValue, encoding: .ascii)
}
print(string)
// MIME-Version: 1.0
// Content-Type: multipart/alternative; boundary="_----------=_176171960423967"
//
// --_----------=_176171960423967
// Content-Disposition: inline
// Content-Transfer-Encoding: quoted-printable
// Content-Type: text/plain; charset="UTF-8"
//
// Hello,
// ...
```

#### Header Decoding

`MIME` extends `String` to encode to and decode from raw IMAP headers. Because encoding creates significantly longer strings, headers can be encoded in multiple segments. Allows selecting the shortest encoding method for arbitrary chunks:

```swift
import MIME

let subject: String = "=?UTF-8?Q?=F0=9F=91=8D=F0=9F=A4=96_S=C3=A4mpl=C3=A9_=C3=A6m?= =?UTF-8?Q?@il_$\\ubject=F0=9F=93=A6?="
print(try subject.headerDecoded())  // "👍🤖 Sämplé æm@il $\\ubject📦"

```

Headers, unless already plain ASCII, are encoded into a single base64 chunk with UTF-8 character encoding:

```swift
import MIME

print(try "❤️❤️❤️éÆ🤖\"\\❤️❤️".headerEncoded())  // "=?UTF-8?B?4p2k77iP4p2k77iP4p2k77iPw6nDhvCfpJYiXOKdpO+4j+KdpO+4jw==?="
print(try "Plain ASCII string requiring 0/no encoding".headerEncoded())  // "Plain ASCII string requiring 0/no encoding"
```

#### Date Formatting

`MIME` includes a formatter that converts between [`Date`](https://developer.apple.com/documentation/foundation/date) and [RFC 822](https://www.rfc-editor.org/rfc/rfc822#section-5) `date-time` string representation.

```swift
import Foundation
import MIME

let formatter: RFC822DateFormatter = RFC822DateFormatter()
let date: Date = try formatter.date(from: "Sat, 06 Dec 2025 01:00:00 -0500 (EST)")
print(date.timeIntervalSince1970)  // 1765000800.0
let string: String = formatter.string(from: date, TimeZone(abbreviation: "EST")!)
print(string)  // "Sat, 06 Dec 2025 01:00:00 -0500"
```

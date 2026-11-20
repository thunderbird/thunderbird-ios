# App Design

Technical overview of project architecture

## Project Structure

In the context of Thunderbird for iOS (Tfi), "project" means literally an [Xcode project file.](https://developer.apple.com/documentation/xcode/creating-an-xcode-project-for-an-app) In this case we're using a [workspace](https://developer.apple.com/documentation/xcode/projects-and-workspaces) to develop Tfi as a thin Xcode project that depends on libraries organized into local packages.

`Thunderbird.xcworkspace` holds three things: the `Thunderbird` app project, the `Core` package and the `Bolt` package.

### Thunderbird Project

`Thunderbird.xcodeproj` has two targets: the SwiftUI app, `Thunderbird`, and its unit tests, `ThunderbirdTests`. Additional targets will be added to support things like widgets, rich notifications and/or watchOS extensions.

The app's source is grouped by screen or concern:

| Folder | Contents |
| --- | --- |
| `Account` | Adding and editing an account: automatic setup, manual server setup and sign-in, including OAuth |
| `AccountList` | The drawer that lists accounts and their mailboxes |
| `EmailDisplay` | The email list and the screen for reading one email |
| `ComposeView` | Writing a new email |
| `Settings` | General settings |
| `FeatureFlags` | Flags that turn unfinished features on or off per distribution (debug, beta, App Store) |
| `Util` | Shared alerts, components, helpers and models |
| `Localization` | Translated strings, one folder per language |

The compose editor is [swift-rich-html-editor](https://github.com/thunderbird/swift-rich-html-editor), the project's one remote package dependency. The reading screen renders an email's HTML in a [WKWebView.](https://developer.apple.com/documentation/webkit/wkwebview)

#### Documentation

The Xcode project includes a [documentation catalog](https://developer.apple.com/documentation/xcode/adding-supplemental-content-to-a-documentation-catalog) for publishing additional articles (like this one) alongside the generated [DocC](https://www.swift.org/documentation/docc) documentation.

In `Core`, the `MIME` and `SMTP` libraries have a catalog of their own, and the package's `README.md` describes most of the libraries.

#### Localization

Tfi plans to launch with language support comparable to [Thunderbird for Android](https://github.com/thunderbird/thunderbird-android) (TfA) by using [Weblate translations](https://hosted.weblate.org/projects/tb-android), published as `Localizable.strings`.

User-facing string localization is accomplished using [`LocalizedStringKey`](https://developer.apple.com/documentation/swiftui/localizedstringkey) in SwiftUI.

<doc:Localization> describes where the strings live and how translations reach this repository.

### Core Package

`Core` is the backend functionality for the app, mostly a kit of standard, modular mail client components. Each library is its own target with its own test target. These libraries were first developed as the "Feature" package.

#### `Account`

The layer the app talks to. `Account` models a mail account, its servers and its credentials, stores accounts on disk and credentials in the keychain, and turns the protocol libraries' mailboxes and messages into one set of types (`Mailbox`, `Email`) that the app displays. It depends on every other library in the package.

#### `Autoconfiguration`

 [Thunderbird Autoconfiguration](https://www.bucksch.org/1/projects/thunderbird/autoconfiguration), often just "autoconfig," is an XML syndication format where email service providers advertise public mail server settings. Given an email address or host name, `Autoconfiguration` library uses a combination of the [Public Suffix List](https://publicsuffix.org), [MX records](https://en.wikipedia.org/wiki/MX_record) and [ISPDB](https://github.com/thunderbird/autoconfig) to find the correct mail server and OAuth settings.

The library also builds the OAuth 2.0 requests used to sign in. `autoconfig` is a command-line tool for running a lookup from Terminal.

#### `EmailAddress`

Parse and validate email addresses. Used by `IMAP`, `JMAP` and `SMTP`.

#### `IMAP` and `SMTP`

Almost every mail server and mail provider support receiving and sending email with [Internet Message Access Protocol](https://en.wikipedia.org/wiki/Internet_Message_Access_Protocol) (IMAP) and [Simple Mail Transfer Protocol](https://en.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol) (SMTP).

Separate, complementary libraries handle email retrieval and sending for all mail accounts with all providers. Both client implementations use [SwiftNIO](https://opensource.apple.com/projects/swiftnio) for [TCP](https://en.wikipedia.org/wiki/Transmission_Control_Protocol) communication with mail servers. `IMAP` builds on [swift-nio-imap](https://github.com/apple/swift-nio-imap) for commands and parsing.

#### `JMAP`

 [JSON Meta Application Protocol](https://jmap.io) (JMAP) is a modern, API-based approach to email that uses standard HTTP requests and responses with JSON serialization for transit. `JMAP` library is a client implementation of both [JMAP core](https://jmap.io/spec/rfc8620) and [JMAP mail](https://jmap.io/spec/rfc8621) protocols, intended to replace IMAP/SMTP for mail accounts with provider support for JMAP.

#### `MIME`

Decode and encode [MIME](https://en.wikipedia.org/wiki/MIME) message bodies: multipart structure, headers, character sets and transfer encodings. `IMAP` and `JMAP` use it to read messages and `SMTP` uses it to write them.

### Bolt Package

[Bolt](https://bolt.thunderbird.net) is Thunderbird's design system. `Bolt` package implements the design system as SwiftUI views, colors and type.

#### `BoltUI`

Vend SwiftUI design system components.

-----

`BoltUI` is unusual, because it depends on SwiftUI and implements views specifically for iOS, macOS and watchOS platforms. Generally, libraries follow these conventions:

* Corresponding test target containing unit test coverage for logic and anything computed; use [Swift Testing.](https://developer.apple.com/documentation/testing)
* Configurable programming interfaces; no user interface, no localization or user-facing strings
* Explicit interfaces and responsibility, encapsulated for being moved into separate repositories and reused in other apps

### Additional Workspace Components

* `Thunderbird.xctestplan` aggregates tests from both app project and packaged libraries. The `ThunderbirdTests` scheme runs it, and so does continuous integration.
* `docs` is a separate documentation site, built with [mdBook](https://rust-lang.github.io/mdBook/) and published to [GitHub Pages.](https://pages.github.com) It holds the architecture diagrams and the guide to writing documentation.
* `fastlane` builds and uploads the app: one lane for TestFlight, one for an App Store release.
* `.github/workflows` runs the build, the tests and the `swift-format` lint on every pull request, and deploys `docs`.
* `CI` and `config` hold scripts and settings for the documentation and security-scan workflows.

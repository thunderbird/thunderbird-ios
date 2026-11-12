# Database Design

Thunderbird for iOS will persist account configurations and email messages locally using a SQLite database.

> Important: This article is a proposal. No database exists in the app yet; see "Current State" below. The work is tracked in [Data Persistence (#395)](https://github.com/thunderbird/thunderbird-ios/issues/395).

## Current State

* Accounts are saved as a JSON file in the app's container, by the `Account` library.
* Passwords and OAuth tokens are saved in the keychain.
* Mailboxes and emails are fetched from the server each time and kept in memory only. Nothing is available offline.
* Caching message bodies and attachments is tracked in [#465](https://github.com/thunderbird/thunderbird-ios/issues/465).

## Background

[SQLite](https://www.sqlite.org) has been the de facto relational database for iOS all along, and on the Mac long before iOS. SQLite is the default backing store for Apple's own [SwiftData](https://developer.apple.com/documentation/swiftdata) and [Core Data](https://developer.apple.com/documentation/coredata), and there are a handful of popular SQLite wrapper libraries (e.g., [FMDB](https://github.com/ccgus/fmdb), [GRDB](https://github.com/groue/GRDB.swift)) for using SQLite without adopting it at the framework level.

Additionally, [Thunderbird for Android](https://github.com/thunderbird/thunderbird-android) uses SQLite for the same purpose of persisting email accounts and messages. There's a real future where Android and iOS, first, share the same SQLite schema(s), then, use the same [KMP](https://kotlinlang.org/docs/multiplatform.html) library that wraps SQLite in a unified interface for both apps.

## Functional Requirements

* Persist all configured accounts, downloaded messages and associated data in a single database, normalized, and using appropriate relationships and constraints.
* Persisted data should be complete enough for app to operate offline: drafting new messages and reading/managing downloaded messages.
* Schema supports both JMAP and IMAP accounts and messages; support for Gmail and/or EWS can be added by simple migrations (e.g., extending existing types, adding tables and relations).
* Search-optimized table (indexed, no relationships) for keeping duplicate account and message data explicitly for searching and displaying search results.
* Export to file formats: SQLite, MBOX, CSV, JSON
* Import from SQLite file; build and rebuild from single schema.

## Message Formats

Tfi intends to support IMAP and JMAP exclusively -- at least, at first. We're adopting the same pragmatic approach that Android takes by supporting IMAP; most of the email world is IMAP, and we can deliver great, private email access for almost every email address at launch.

[JMAP](https://jmap.io) support is a Thunderbird-wide project. Tfi's email support being designed from scratch is an opportunity to be the first of our clients to support JMAP, followed closely by TfA.

### IMAP

Tfi depends on [swift-nio-imap](https://github.com/apple/swift-nio-imap) for IMAP support. swift-nio-imap provides conveniences for operating on multipart message bodies, without transposing or modeling the raw binary. It does the heavy lifting, without committing Tfi to additional abstractions on top of IMAP. Message bodies are decoded by the `MIME` library.

### JMAP

JMAP is designed to work with IMAP. In addition to modern names for the same IMAP concepts (e.g., "folder" => "mailbox" or "message" => "email"), JMAP is different at the database layer: It replaces IMAP multipart message bodies with modeled JSON body parts.

### POP

Tfi doesn't plan to support configuring POP3 accounts for sending or receiving email. However, importing archived POP messages for searching and reading may be desired. This is outside the initial scope for Tfi, but database design allows for POP-format messages to be added later.

### Gmail

Following Android, [Gmail](https://developers.google.com/workspace/gmail/imap/imap-smtp) is supported, first as a standard IMAP provider, then as a superset of IMAP, by leveraging swift-nio-imap extensions for Gmail. The `IMAP` library already reads Gmail labels.

### Exchange

Tfi doesn't plan to support [EWS](https://learn.microsoft.com/en-us/exchange/client-developer/exchange-web-services/ews-applications-and-the-exchange-architecture) directly. [Microsoft 365](https://www.microsoft365.com) email accounts will be supported as a standard IMAP provider.

## Design Goals

Each of the handful of libraries that Tfi uses to actually send and receive email reflects the protocol's nomenclature in its public interface. For example, `IMAP` groups `Message` values in a `Mailbox`; `JMAP` groups `Email` values in a `Mailbox`. For the user, it's all one type of each thing, normalized around JMAP naming, which is less ambiguous, less likely to collide. The `Account` library already does this in memory, with its own `Mailbox` and `Email` types.

And we want the database to reflect the unification, so that both IMAP and JMAP messages are stored, pre-processed, as a standard `Email`, and all message data lives (primarily) in a single `EMAIL` table.

### Attachments and Raw Multipart Message Data

Downloaded attachments and/or original multipart message data can be stored in data blobs on different tables and linked/related. Alternately, either or both can be cached to files on disk, with the database storing links as a [`URLProtocol`](https://developer.apple.com/documentation/foundation/urlprotocol) or similar that first tries to open the locally linked attachment file, falling back to downloading from server.

### Search

SQLite provides powerful, instantaneous searching, regardless of database size. The database design for Tfi will include a separate, search-optimized table where searchable metadata/predicates/weighting/keywords can be entered for any types that we would want to search, at least: email, email addresses, folders. User-facing search can then be constrained by type.

Additionally, the idea is to build one big search index with a search index item model that includes enough preview information (i.e., sender, subject, plain-text preview) to accomplish the following using only the search index table:

* Find and display search results in app.
* Generate a [Core Spotlight](https://developer.apple.com/documentation/CoreSpotlight) searchable index.

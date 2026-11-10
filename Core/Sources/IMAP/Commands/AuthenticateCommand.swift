// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore
import NIOIMAP

/// `AUTHENTICATE`: sign in with a SASL mechanism, sending the whole credential as the initial response.
///
/// On success the command yields the capabilities the server advertises to the now-authenticated user; on a
/// rejected credential it fails with ``IMAPError/authenticationFailed(_:failure:)``. See ``AuthenticateHandler``
/// for the exchange.
///
/// See [RFC 3501, section 6.2.2](https://www.rfc-editor.org/rfc/rfc3501#section-6.2.2) for the command and
/// [RFC 4959](https://www.rfc-editor.org/rfc/rfc4959) for the initial response (`SASL-IR`).
struct AuthenticateCommand: IMAPCommand {
    let authentication: Authentication

    init(_ authentication: Authentication) {
        self.authentication = authentication
    }

    // MARK: IMAPCommand
    typealias Result = [Capability]
    typealias Handler = AuthenticateHandler

    var name: String { "authenticate \"\(authentication.user)\"" }

    func tagged(_ tag: String) -> NIOIMAPCore.TaggedCommand {
        TaggedCommand(
            tag: Command.Tag(stringLiteral: tag),
            command:
                .authenticate(
                    mechanism: authentication.mechanism,
                    initialResponse: try? authentication.initialResponse
                )
        )
    }

    // The handler has to know how this command's mechanism answers a challenge, which the generic
    // `init(tag:promise:)` can't tell it. Hand over only the few bytes of that answer, not `authentication`
    // itself, so the handler never holds the password or token.
    func handler(tag: String, promise: EventLoopPromise<Result>) -> Handler {
        AuthenticateHandler(tag: tag, promise: promise, challengeResponse: authentication.challengeResponse)
    }
}

/// Handles the server's responses during an `AUTHENTICATE` exchange: collects capabilities, answers challenges,
/// and turns the final tagged response into a result.
///
/// ## Why `AUTHENTICATE` needs its own handler
///
/// Most commands are a single request followed by responses. `AUTHENTICATE` is a conversation: the server may
/// reply with a challenge (a `+` continuation request) and then *wait for the client* before it says anything
/// else. A handler that only listens, as `CapabilityHandler` does, deadlocks against such a server. With a
/// rejected OAuth token that looks like this:
///
/// ```
/// C: A01 AUTHENTICATE XOAUTH2 dXNlcj1zb21l…
/// S: + eyJzdGF0dXMiOiI0MDEi…          (challenge: "your token was rejected, here is why")
///                                      (server waits for an answer; client waits for A01)
///                                      (…60 seconds later the command times out)
/// ```
///
/// ## The exchange, as this handler runs it
///
/// The credential travels in the command itself as the initial response, so a server that accepts it needs no
/// challenge at all:
///
/// ```
/// C: A01 AUTHENTICATE XOAUTH2 dXNlcj1zb21l…
/// S: * CAPABILITY IMAP4rev1 IDLE NAMESPACE …
/// S: A01 OK Success
/// ```
///
/// Some servers fold the capability list into the `OK` instead: `S: A01 OK [CAPABILITY IMAP4rev1 IDLE …] Success`.
///
/// A server that rejects an OAuth token sends the reason as a challenge, the client acknowledges it, and only
/// then does the server end the command:
///
/// ```
/// C: A01 AUTHENTICATE OAUTHBEARER bixhPXVzZXJAZXhhbXBsZS5jb20s…
/// S: + eyJzdGF0dXMiOiJpbnZhbGlkX3Rva2VuIiwic2NvcGUiOiJleGFtcGxlX3Njb3BlIi…
/// C: AQ==                              (0x01 for OAUTHBEARER; an empty line for XOAUTH2)
/// S: A01 NO SASL authentication failed
/// ```
///
/// The acknowledgement is required, not a courtesy.
/// [RFC 7628, section 3.2.3](https://www.rfc-editor.org/rfc/rfc7628#section-3.2.3) for `OAUTHBEARER`: "The client
/// MUST then send either an additional client response consisting of a single %x01 (control A) character to the
/// server in order to allow the server to finish the exchange or a SASL abort message…". Google's
/// [XOAUTH2 protocol](https://developers.google.com/workspace/gmail/imap/xoauth2-protocol) for `XOAUTH2`: "The
/// SASL protocol requires clients to send an empty response to this challenge."
///
/// The reason arrives in a challenge, and not in the `NO`, because SASL allows additional data only in a
/// successful outcome ([RFC 4422, section 3.6](https://www.rfc-editor.org/rfc/rfc4422#section-3.6)).
///
/// ## What NIOIMAP does and doesn't do
///
/// NIOIMAP's `IMAPClientHandler` parses the continuation request and delivers it as
/// `Response.authenticationChallenge`, with the payload already base64-decoded. It does not answer: that is left
/// to the handler behind it, which writes `CommandStreamPart.continuationResponse`. NIOIMAP base64-encodes that
/// response and appends the line ending.
///
/// - Important: Answering matters beyond the timeout. While a challenge is unanswered, NIOIMAP's client state
///   machine accepts a continuation response and nothing else. Writing any other command to the connection in
///   that state traps (`Fatal error: Continuation responses only`), and a tagged response that arrives in that
///   state moves the connection into an error state that refuses every later command. Every challenge must be
///   answered exactly once, which is what `channelRead` does.
class AuthenticateHandler: IMAPCommandHandler, @unchecked Sendable {
    /// Capabilities the server announced during the exchange, if it announced any.
    ///
    /// Servers usually announce a new capability list on a successful sign-in, since what an authenticated user
    /// may do differs from what was on offer before. The list arrives either as an untagged `CAPABILITY` response
    /// before the tagged `OK` (Gmail does this) or as a `CAPABILITY` response code inside the `OK` itself.
    private(set) var capabilities: Result = []

    /// The reason the server gave for rejecting the credential; `nil` until a challenge carrying one arrives.
    ///
    /// Held here because the reason and the rejection arrive in two separate responses: the challenge comes first
    /// and the tagged `NO` that actually fails the command comes after the client has answered.
    private(set) var failure: AuthenticationFailure?

    /// What to send back for each challenge; see `Authentication.challengeResponse` for the per-mechanism rules.
    private let challengeResponse: ByteBuffer

    /// Creates a handler that answers challenges the way the command's mechanism requires.
    ///
    /// - Parameter challengeResponse: The decoded bytes to answer each challenge with. NIOIMAP base64-encodes
    ///   them, so an empty buffer goes out as an empty line and `0x01` as `AQ==`.
    init(tag: String, promise: EventLoopPromise<Result>, challengeResponse: ByteBuffer) {
        self.promise = promise
        self.tag = tag
        self.challengeResponse = challengeResponse
    }

    // MARK: IMAPCommandHandler
    typealias InboundIn = Response
    typealias InboundOut = Response
    typealias Result = [Capability]

    var clientBug: String? = nil
    let promise: EventLoopPromise<Result>
    let tag: String

    /// Creates a handler that answers every challenge with an empty response.
    ///
    /// Required by `IMAPCommandHandler`. ``AuthenticateCommand`` doesn't use it; it builds its handler with the
    /// response its mechanism calls for.
    required convenience init(tag: String, promise: EventLoopPromise<Result>) {
        self.init(tag: tag, promise: promise, challengeResponse: ByteBuffer())
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let response: Response = unwrapInboundIn(data)
        clientBug = response.clientBug
        switch response {
        case .authenticationChallenge(let challenge):
            // The server is now waiting on us. For the mechanisms this client implements the credential was
            // already sent in full, so a challenge can only be the server explaining a rejection.

            // 1. Remember the reason. The command hasn't failed yet; the tagged NO does that. If the payload
            //    isn't an OAuth error result, keep whatever an earlier challenge provided.
            failure = AuthenticationFailure(challenge) ?? failure

            // 2. Answer, so that the server can send that NO. This is the step whose absence caused the hang.
            //    Written from here (and not from `IMAPClient`) so that it goes out on the event loop, in order,
            //    the moment the challenge is read.
            let answer: IMAPClientHandler.Message = .part(.continuationResponse(challengeResponse))
            context.writeAndFlush(NIOAny(answer)).whenFailure { [promise] error in
                // If the answer can't be written the server will never reply; fail now and don't wait for the
                // timeout. Failing a promise that has already completed does nothing.
                promise.fail(error)
            }
        case .tagged(let taggedResponse):
            // The tagged response ends the command, one way or another
            switch taggedResponse.state {
            case .ok(let text):
                // Signed in. The server may have put its capability list in the OK itself and skipped the
                // untagged response: "A server MAY include a CAPABILITY response code in the tagged OK response
                // of a successful AUTHENTICATE command in order to send capabilities automatically."
                // (RFC 3501, section 6.2.2). If it sent both, the OK is the later word and wins.
                if case .capability(let capabilities)? = text.code {
                    self.capabilities = capabilities.map { Capability($0) }
                }
                // A server that sent neither yields an empty list, which `IMAPClient` treats as "nothing to
                // merge".
                promise.succeed(capabilities)
            case .no(let text):
                // NO: "authenticate failure: unsupported authentication mechanism, credentials rejected"
                // (RFC 3501, section 6.2.2). For the OAuth mechanisms `IMAPClient` checks that the server
                // advertises the mechanism before sending, so in practice this is a rejected credential.
                promise.fail(IMAPError.authenticationFailed(text.text, failure: failure))
            case .bad(let text):
                // BAD: "command unknown or arguments invalid, authentication exchange cancelled". A protocol
                // problem and not a verdict on the credential, so it stays a plain command failure and
                // doesn't send callers off to refresh a token that may be fine.
                promise.fail(IMAPError.commandFailed(text.text))
            }
        case .untagged(let payload):
            switch payload {
            case .capabilityData(let capabilities):
                self.capabilities = capabilities.map { Capability($0) }
            default:
                break
            }
        default:
            break
        }
        context.fireChannelRead(data)
    }
}

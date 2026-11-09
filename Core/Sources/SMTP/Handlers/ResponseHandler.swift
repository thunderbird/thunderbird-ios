// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOCore

/// A reply from the server, reduced to success or failure.
enum Response {
    /// A positive reply (2xx or 3xx): the code, and the text after it.
    case ok(Int, String)
    /// A negative or unexpected reply: the whole line.
    case error(String)
}

/// Turns each line from the server into a ``Response``, and skips the continuation lines of a multiline reply.
///
/// Each line is read as a three-digit code followed by a space (the last line of a reply) or a hyphen (more lines
/// follow). A last line with a 2xx or 3xx code becomes ``Response/ok(_:_:)``, a continuation line is dropped, and any
/// other line becomes ``Response/error(_:)``.
///
/// - Important: A reply that is only a code, such as `250` with no text, which
///   [RFC 5321](https://www.rfc-editor.org/rfc/rfc5321#section-4.2) allows, can't be read and fails with
///   ``SMTPError/responseNotDecoded``. Because continuation lines are dropped, the capabilities the server lists
///   after `EHLO` are never seen.
// TODO: Accept a code with no text, and keep the `EHLO` capability lines so the client can check for STARTTLS and AUTH.
final class ResponseHandler: ChannelInboundHandler, Sendable {

    // MARK: ChannelInboundHandler
    typealias InboundIn = ByteBuffer
    typealias InboundOut = Response

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer: ByteBuffer = unwrapInboundIn(data)
        guard let prefix: String = buffer.readString(length: 4),
            let code: Int = Int(prefix.dropLast())
        else {
            context.fireErrorCaught(SMTPError.responseNotDecoded)
            return
        }
        let string: String = buffer.readString(length: buffer.readableBytes) ?? ""
        switch (prefix.first!, prefix.last!) {
        case ("2", " "), ("3", " "):
            context.fireChannelRead(wrapInboundOut(.ok(code, string)))
        case (_, "-"):
            break  // Ignore messages except OK and error
        default:
            context.fireChannelRead(wrapInboundOut(.error("\(prefix)\(string)")))
        }
    }
}

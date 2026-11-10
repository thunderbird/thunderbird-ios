// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// The errors from sending mail. ``SMTPClient`` throws `SMTPError`.
public enum SMTPError: Error, CustomStringConvertible, Equatable {
    /// The recipient's address is empty.
    case emailRecipientNotFound
    /// The server closed the connection before the send finished.
    case remoteConnectionClosed
    /// The connection should be encrypted, but TLS wasn't in place when it was needed.
    case requiredTLSNotConfigured
    /// A line from the server didn't start with a three-digit code followed by a space or hyphen.
    case responseNotDecoded
    /// The server replied with an error, or another kind of error happened. The text is the server's reply, or the
    /// other error's description.
    case response(String)

    /// Wrap any error: an `SMTPError` is kept as it is, and any other error becomes ``response(_:)`` with its localized
    /// description.
    init(_ error: Error) {
        self = error as? Self ?? .response(error.localizedDescription)
    }

    // MARK: CustomStringConvertible
    public var description: String {
        switch self {
        case .emailRecipientNotFound: "Email recipient not found"
        case .remoteConnectionClosed: "Remote connection closed"
        case .requiredTLSNotConfigured: "Required TLS not configured"
        case .responseNotDecoded: "Response not decoded"
        case .response(let string): "Response: \(string)"
        }
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Describes possible errors related to account setup, authentication, protocols, and operations.
public enum AccountError: CustomStringConvertible, Error, Equatable {
    /// An error occurred during authorization.
    case authorization(Error)
    /// An error occurred during account autoconfiguration.
    case autoconfig(Error)
    /// Email address was not found.
    case emailAddressNotFound
    /// Email address is not supported.
    case emailAddressNotSupported
    /// A file manager-related error.
    case fileManager(Error)
    /// An IMAP protocol error.
    case imap(IMAPError)
    /// A JMAP protocol error.
    case jmap(JMAPError)
    /// A MIME-related error.
    case mime(MIMEError)
    /// An SMTP protocol error.
    case smtp(SMTPError)

    /// Initializes an AccountError from another error type, if possible.
    public init?(_ error: Error) {
        if let error: Self = error as? Self {
            self = error
        } else {
            switch error {
            case let error as IMAPError:
                self = .imap(error)
            case let error as JMAPError:
                self = .jmap(error)
            case let error as MIMEError:
                self = .mime(error)
            case let error as SMTPError:
                self = .smtp(error)
            default:
                return nil
            }
        }
    }

    // MARK: CustomStringConvertible
    /// A string describing the error for display or debugging.
    public var description: String {
        switch self {
        case .authorization(let error): "Authorization: \(error)"
        case .autoconfig(let error): "Autoconfiguration: \(error)"
        case .emailAddressNotFound: "Email address not found"
        case .emailAddressNotSupported: "Email address not supported"
        case .fileManager(let error): "FileManager: \(error)"
        case .imap(let error): "IMAP: \(error)"
        case .jmap(let error): "JMAP: \(error)"
        case .mime(let error): "MIME: \(error)"
        case .smtp(let error): "SMTP: \(error)"
        }
    }

    // MARK: Equatable
    /// AccountErrors are equal if their descriptions are equal.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.description == rhs.description
    }
}

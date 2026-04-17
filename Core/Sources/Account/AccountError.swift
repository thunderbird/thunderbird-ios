public enum AccountError: CustomStringConvertible, Error, Equatable {
    case autoconfig(Error)
    case fileManager(Error)
    case imap(IMAPError)
    case jmap(JMAPError)
    case mime(MIMEError)
    case smtp(SMTPError)

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
    public var description: String {
        switch self {
        case .autoconfig(let error): "Autoconfiguration: \(error)"
        case .fileManager(let error): "FileManager: \(error)"
        case .imap(let error): "IMAP: \(error)"
        case .jmap(let error): "JMAP: \(error)"
        case .mime(let error): "MIME: \(error)"
        case .smtp(let error): "SMTP: \(error)"
        }
    }

    // MARK: Equatable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.description == rhs.description
    }
}

@testable import Account
import Testing
import Foundation

struct AccountErrorTests {
    @Test func errorInit() {
        #expect(AccountError(AccountError.autoconfig(URLError(.fileDoesNotExist))) == .autoconfig(URLError(.fileDoesNotExist)))
        #expect(AccountError(IMAPError.serverDisconnected) == .imap(.serverDisconnected))
        #expect(AccountError(JMAPError.underlying(URLError(.fileDoesNotExist))) == .jmap(.underlying(URLError(.fileDoesNotExist))))
        #expect(AccountError(MIMEError.characterSetNotFound) == .mime(.characterSetNotFound))
        #expect(AccountError(SMTPError.remoteConnectionClosed) == .smtp(.remoteConnectionClosed))
        #expect(AccountError(URLError(.fileDoesNotExist)) == nil)
    }

    @Test func description() {
        #expect(AccountError.fileManager(URLError(.fileDoesNotExist)).description == "FileManager: Error Domain=NSURLErrorDomain Code=-1100 \"(null)\"")
        #expect(AccountError.imap(.timedOut(seconds: 60)).description == "IMAP: Timed out after 60 seconds")
        #expect(AccountError.jmap(.method(.accountNotSupportedByMethod)).description == "JMAP: Method error: Account not supported by method")
        #expect(AccountError.mime(.characterSetNotFound).description == "MIME: Character set not found")
        #expect(AccountError.smtp(.requiredTLSNotConfigured).description == "SMTP: Required TLS not configured")
    }

    @Test func equal() {
        #expect(AccountError.fileManager(URLError(.fileDoesNotExist)) == AccountError.fileManager(URLError(.fileDoesNotExist)))
        #expect(AccountError.fileManager(URLError(.fileDoesNotExist)) != AccountError.fileManager(URLError(.badURL)))
        #expect(AccountError.imap(.timedOut(seconds: 60)) == AccountError.imap(.timedOut(seconds: 60)))
        #expect(AccountError.imap(.timedOut(seconds: 60)) != AccountError.imap(.timedOut(seconds: 30)))
    }
}

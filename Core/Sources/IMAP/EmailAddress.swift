// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import MIME
import NIOIMAPCore

extension [EmailAddressListElement] {
    var addresses: [EmailAddressProtocol] { map { $0.address } }
}

extension EmailAddressListElement {
    var address: EmailAddressProtocol {
        switch self {
        case .singleAddress(let address): EmailAddress(stringLiteral: "\(address)")
        case .group(let group): EmailAddress.Group(group.children.map { EmailAddress(stringLiteral: "\($0)") }, label: "\(group)")
        }
    }
}

extension NIOIMAPCore.EmailAddressGroup: @retroactive CustomStringConvertible {

    // MARK: CustomStringConvertible
    public var description: String {
        let description: String = groupName.readableBytesView.description
        return (try? description.headerDecoded()) ?? description
    }
}

extension NIOIMAPCore.EmailAddress: @retroactive CustomStringConvertible {

    // MARK: CustomStringConvertible
    public var description: String {
        guard let mailbox: String = mailbox?.readableBytesView.description,
            !mailbox.isEmpty,
            let host: String = host?.readableBytesView.description,
            !host.isEmpty
        else {
            return ""
        }
        let description: String = "\(mailbox)@\(host)"
        if let personName: String = try? personName?.readableBytesView.description.headerDecoded(),
            !personName.isEmpty
        {
            return "\(personName) <\(description)>"
        }
        return description
    }
}

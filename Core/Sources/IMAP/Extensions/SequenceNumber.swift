// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOIMAPCore

public typealias SequenceNumber = NIOIMAPCore.SequenceNumber
public typealias SequenceSet = NIOIMAPCore.MessageIdentifierSetNonEmpty<SequenceNumber>

extension SequenceNumber: @retroactive CustomStringConvertible {

    // MARK: CustomStringConvertible
    public var description: String { debugDescription }
}

extension SequenceSet {
    init(_ sequenceNumber: SequenceNumber) {
        self.init(range: MessageIdentifierRange(sequenceNumber))
    }
}

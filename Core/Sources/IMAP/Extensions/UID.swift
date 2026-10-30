// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOIMAPCore

public typealias UID = NIOIMAPCore.UID
public typealias UIDSet = NIOIMAPCore.UIDSetNonEmpty

extension UID: @retroactive CustomStringConvertible {

    // MARK: CustomStringConvertible
    public var description: String { debugDescription }
}

extension UIDSet {
    init(_ uid: UID) {
        self.init(range: MessageIdentifierRange(uid))
    }
}

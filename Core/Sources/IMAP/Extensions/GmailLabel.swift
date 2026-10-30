// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MIME
import NIOIMAPCore
import NIOCore

public typealias GmailLabel = NIOIMAPCore.GmailLabel

extension GmailLabel: @retroactive CustomStringConvertible {

    // MARK: CustomStringConvertible
    public var description: String { makeDisplayString() }

    // MARK: Sample data for tests
    public static let testLabels = [
        GmailLabel(ByteBuffer(string: "\\starred")),
        GmailLabel(ByteBuffer(string: "\\important"))
    ]
}

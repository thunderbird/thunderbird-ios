// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Possible `set` ``Method`` mutations, part of [JMAP corel](https://jmap.io/spec/rfc8620/#section-5.3)
public enum MethodAction: CustomStringConvertible {
    case create([String: Any])
    case update([String: Any])
    case destroy([String])

    // MARK: CustomStringConvertible
    public var description: String {
        switch self {
        case .create: "create"
        case .update: "update"
        case .destroy: "destroy"
        }
    }
}

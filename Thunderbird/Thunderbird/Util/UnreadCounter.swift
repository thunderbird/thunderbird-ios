// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A small badge showing how many messages are unread, drawn in the accent color or inverted when some are new.
///
/// - Important: Both values are copied into `@State` when the badge is created, so a badge that stays on screen may not
///   follow later changes to the count.
// TODO: Verify on a device, and store `unreadCount` and `hasNew` as plain properties if the badge doesn't update.
struct UnreadCounter: View {
    /// - Parameters:
    ///   - unreadCount: The number of unread messages.
    ///   - hasNew: Whether any of the unread messages count as new. Defaults to `false`.
    init(unreadCount: Int, hasNew: Bool = false) {
        self.unreadCount = unreadCount
        self.hasNew = hasNew
    }

    @State private var unreadCount: Int
    @State private var hasNew: Bool = false

    var body: some View {
        Text("\(unreadCount)")
            .font(.caption2)
            .padding(.horizontal, 6)
            .foregroundColor(hasNew ? .accent : .white)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        (hasNew ? .accent : .white),
                        style: StrokeStyle(
                            lineWidth: 1
                        )
                    )
                    .fill(hasNew ? .white : .accent)
                    .frame(width: 20, height: 17)
            }
    }
}

#Preview {
    UnreadCounter(unreadCount: 8, hasNew: false)
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

///- Parameters:
///  - unreadCount: number of unread messages
///  - hasNew: do any of the unread messages qualify as 'new'
struct UnreadCounter: View {
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

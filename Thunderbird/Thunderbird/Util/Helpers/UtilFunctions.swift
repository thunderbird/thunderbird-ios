// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

// Catch all for functions needed across the app

/// Make the text for an avatar from a person's name.
///
/// - Parameter displayName: A name of one or two words. More than two words are handled by using only the first two.
/// - Returns: The capitalized first letters of the first two words ("Denny Klein" gives "DK"), one letter for a
///   one-word name, or an empty string for an empty name.
func createAvatarText(displayName: String) -> String {
    let splitName = displayName.split(separator: " ")
    if splitName.count >= 2 {
        let letter = "\(splitName[0].capitalized.first!)\(splitName[1].capitalized.first!)"
        return letter
    } else if (!splitName.isEmpty) {
        return String(splitName[0].capitalized.first!)
    } else {
        return ""
    }
}

/// Select color from design approved color list
///
/// - Returns: The name of one of the app's user colors, such as `user-blue`, chosen at random.
/// - Note: Only `AvatarView`'s preview calls this. Accounts get their avatar color from `Account.avatarColor`.
// TODO: Remove this function, or use it to pick an account's color when it's created.
func randomizeAvatarColor() -> String {
    let userColors: [String] = [
        "user-red", "user-orange", "user-yellow", "user-green", "user-blue", "user-pink",
        "user-purple"
    ]
    return userColors.randomElement()!
}

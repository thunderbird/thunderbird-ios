// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Bolt
import SwiftUI

/// A labeled form field for entering text, with automatic formatting such as capitalization turned off.
struct TextEntryWrapper: View {

    /// - Parameters:
    ///   - header: The label shown with the field. Empty by default.
    ///   - suggestion: The placeholder, such as an example value, that gives the field context. Empty by default.
    ///   - entryText: The text entered. Defaults to a constant empty string, so the field can't be edited.
    init(
        _ header: LocalizedStringKey = "",
        _ suggestion: String = "",
        _ entryText: Binding<String> = .constant(""),
    ) {
        headerText = header
        suggestionText = suggestion
        _entryText = entryText
    }

    private var headerText: LocalizedStringKey
    private var suggestionText: String
    @Binding private var entryText: String

    // MARK: View
    var body: some View {
        TextField(suggestionText, text: $entryText)
            .formInput(headerText)
            .autoFormattingDisabled()
            .focusable()
    }
}

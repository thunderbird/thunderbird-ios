// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A labeled form field for entering a whole number, such as a port, with a number pad on iOS.
///
/// The binding is `nil` while the field is empty.
// TODO: Accept only whole numbers from 1 to 65535 for ports, and commit the pending edit before the form is saved
// (#622).
struct NumEntryWrapper: View {

    /// - Parameters:
    ///   - header: The label shown with the field.
    ///   - suggestion: The placeholder, such as an example value, that gives the field context.
    ///   - entryText: The number entered, or `nil` if the field is empty.
    init(
        _ header: LocalizedStringKey,
        _ suggestion: String,
        _ entryText: Binding<Int?>,
    ) {
        headerText = header
        suggestionText = suggestion
        _entryText = entryText
    }

    private var headerText: LocalizedStringKey
    private var suggestionText: String
    @Binding private var entryText: Int?

    // MARK: View
    var body: some View {
        TextField(suggestionText, value: $entryText, formatter: NumberFormatter())
            .formInput(headerText)
            .autocorrectionDisabled()
            #if os(iOS)
        .keyboardType(.numberPad)
            #endif
            .focusable()
    }
}

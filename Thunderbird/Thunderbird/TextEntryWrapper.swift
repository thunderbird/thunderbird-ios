//
//  TextEntryWrapper.swift
//  Thunderbird
//
//  Created by Ashley Soucar on 8/26/25.
//
import SwiftUI

struct TextEntryWrapper: View {
    init(
        _ header: LocalizedStringResource = "",
        _ suggestion: String = "",
        _ entryText: Binding<String> = .constant(""),
    ) {
        headerText = header
        suggestionText = suggestion
        _entryText = entryText
    }
    private var headerText: LocalizedStringResource
    private var suggestionText: String
    @Binding private var entryText: String

    // MARK: View
    var body: some View {
        Text(headerText)
            .listRowSeparator(.visible, edges: .bottom)
        TextField(suggestionText, text: $entryText)
            .listRowSeparator(.hidden)
            .textFieldStyle(.plain)
            .autocorrectionDisabled()
            #if os(iOS)
        .autocapitalization(.none)
            #endif
            .focusable()

    }
}

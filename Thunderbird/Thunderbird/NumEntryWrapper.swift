//
//  NumEntryWrapper.swift
//  Thunderbird
//
//  Created by Ashley Soucar on 8/26/25.
//
import SwiftUI

struct NumEntryWrapper: View {
    init(
        _ header: LocalizedStringResource,
        _ suggestion: String,
        _ entryText: Binding<Int?>,
    ) {
        headerText = header
        suggestionText = suggestion
        _entryText = entryText
    }
    private var headerText: LocalizedStringResource
    private var suggestionText: String
    @Binding private var entryText: Int?

    // MARK: View
    var body: some View {
        Text(headerText)
            .listRowSeparator(.visible, edges: .bottom)
        TextField(suggestionText, value: $entryText, formatter: NumberFormatter())
            #if os(iOS)
        .keyboardType(.numberPad)
        .listRowSeparator(.hidden)
        .textFieldStyle(.plain)
        .autocapitalization(.none)
            #endif
            .autocorrectionDisabled()
            .focusable()

    }
}

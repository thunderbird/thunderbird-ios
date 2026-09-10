// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import InfomaniakRichHTMLEditor
import SwiftUI

struct ComposeToolbar: View {
    init(
        textAttributes: TextAttributes,
        isShowingLinkAlert: Bool = false,
        linkText: String = "",
        linkUrl: String = "",
        keyboardShown: Binding<Bool>,
        selection: Binding<String>
    ) {
        _keyboardShown = keyboardShown
        _selection = selection
        self.textAttributes = textAttributes
        self.isShowingLinkAlert = isShowingLinkAlert
        self.linkText = linkText
        self.linkUrl = linkUrl
    }

    @State private var textAttributes: TextAttributes
    @State private var isShowingLinkAlert: Bool
    @State private var linkText: String = ""
    @State private var linkUrl: String = ""
    @Binding private var keyboardShown: Bool
    @Binding private var selection: String

    var body: some View {
        // Inline bindings allow us to leave the properties as private (set)
        // within `TextAttributes`, and still respond to events.
        let foregroundColor = Binding<Color>(
            get: { textAttributes.foregroundColor ?? .black },
            set: { textAttributes.setForegroundColor(PlatformColor($0)) }
        )

        let backgroundColor = Binding<Color>(
            get: { textAttributes.backgroundColor ?? .white },
            set: { textAttributes.setBackgroundColor(PlatformColor($0)) }
        )

        ScrollView(.horizontal) {
            Divider()

            HStack(spacing: 4) {
                EditorToolbarButton(systemImage: "keyboard.chevron.compact.down", isActive: false) {
                    keyboardShown.toggle()
                }

                ColorPicker("", selection: foregroundColor, supportsOpacity: false)
                    .labelsHidden()
                    .padding(.leading, 8)
                    // Opacity below .02 seems to disable hit testing for the picker.
                    .opacity(0.02)
                    .overlay {
                        Image(systemName: "character.square")
                            .foregroundStyle(textAttributes.foregroundColor ?? .black)
                            // Additional padding is needed to center the overlay image
                            // within the color picker area.
                            .padding(.leading, 8)
                            .allowsHitTesting(false)
                    }

                ColorPicker("", selection: backgroundColor, supportsOpacity: false)
                    .labelsHidden()
                    .padding(.leading, 8)
                    .opacity(0.02)
                    .overlay {
                        ZStack {
                            Circle()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(textAttributes.backgroundColor ?? .white)
                            Image(systemName: "character.square")
                                .foregroundStyle(textAttributes.foregroundColor ?? .black)
                        }
                        .allowsHitTesting(false)
                        .padding(.leading, 8)
                    }

                Divider()
                    .frame(height: 20)

                EditorToolbarButton(systemImage: "link", isActive: textAttributes.hasLink) {
                    clearLinkInfo()

                    // Assign the default link text to the selected text in the editor.
                    linkText = selection
                    // Remove focus from the webview editor so that focus can be assigned to the alert view text fields.
                    keyboardShown = false
                    // Display the alert to assign link information.
                    isShowingLinkAlert = true
                }
                .alert("Add a link", isPresented: $isShowingLinkAlert) {
                    TextField("Text", text: $linkText)

                    TextField("URL", text: $linkUrl)

                    Button("Submit") {
                        if linkText.isEmpty || linkUrl.isEmpty {
                            textAttributes.unlink()
                            keyboardShown = true
                        } else if let url = URL(string: linkUrl) {
                            keyboardShown = true
                            textAttributes.addLink(url: url, text: linkText)
                        } else {
                            // TODO: Display a warning message here.
                            print("error adding link")
                        }
                    }

                    Button("Cancel", role: .cancel) {
                        if linkText.isEmpty || linkUrl.isEmpty {
                            keyboardShown = true
                        }
                    }
                }

                Divider()
                    .frame(height: 20)

                EditorToolbarButton(systemImage: "bold", isActive: textAttributes.hasBold) {
                    textAttributes.bold()
                }
                EditorToolbarButton(systemImage: "italic", isActive: textAttributes.hasItalic) {
                    textAttributes.italic()
                }
                EditorToolbarButton(systemImage: "underline", isActive: textAttributes.hasUnderline) {
                    textAttributes.underline()
                }
                EditorToolbarButton(systemImage: "strikethrough", isActive: textAttributes.hasStrikethrough) {
                    textAttributes.strikethrough()
                }

                Divider()
                    .frame(height: 20)

                EditorToolbarButton(systemImage: "list.number", isActive: textAttributes.hasOrderedList) {
                    textAttributes.orderedList()
                }
                EditorToolbarButton(systemImage: "list.bullet", isActive: textAttributes.hasUnorderedList) {
                    textAttributes.unorderedList()
                }

                Divider()
                    .frame(height: 20)

                EditorToolbarButton(systemImage: "decrease.indent", isActive: false) {
                    textAttributes.outdent()
                }
                EditorToolbarButton(systemImage: "increase.indent", isActive: false) {
                    textAttributes.indent()
                }

                Divider()
                    .frame(height: 20)

                EditorToolbarButton(systemImage: "arrow.uturn.backward", isActive: false) {
                    textAttributes.undo()
                }
                EditorToolbarButton(systemImage: "arrow.uturn.forward", isActive: false) {
                    textAttributes.redo()
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(height: 44)
    }

    private func clearLinkInfo() {
        linkText = ""
        linkUrl = ""
    }
}

struct EditorToolbarButton: View {
    let systemImage: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body)
                .frame(width: 36, height: 36)
                .foregroundStyle(isActive ? Color.accentColor : .primary)
                .background(isActive ? Color.accentColor.opacity(0.2) : .clear, in: .rect(cornerRadius: 12))
        }
    }
}

#Preview {
    @Previewable @State var textAttributes = TextAttributes()
    @Previewable @State var keyboardShown = false
    @Previewable @State var selection = ""

    ComposeToolbar(textAttributes: textAttributes, keyboardShown: $keyboardShown, selection: $selection)
}

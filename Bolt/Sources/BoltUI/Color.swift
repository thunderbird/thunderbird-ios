// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

extension Color {
    var isDynamic: Bool { resolved().dark != nil }

    func resolve(for colorScheme: ColorScheme) -> Resolved {
        resolve(in: EnvironmentValues(colorScheme))
    }

    func resolved() -> (any: Resolved, dark: Resolved?) {
        let resolved: (Resolved, Resolved) = (resolve(for: .light), resolve(for: .dark))
        return (resolved.0, resolved.1 != resolved.0 ? resolved.1 : nil)
    }

    // Programmatically create SwiftUI dynamic color
    init(_ any: Self, _ dark: Self? = nil) {
        #if os(watchOS)
        self = dark ?? any  // Apple Watch uses dark color, if available
        #else
        if let dark, dark != any {
            #if canImport(AppKit)
            self.init(
                nsColor: NSColor(name: nil) { appearance in
                    switch appearance.name {
                    case .darkAqua:
                        return NSColor(dark)
                    default:
                        return NSColor(any)
                    }
                })
            #elseif canImport(UIKit)
            self.init(
                uiColor: UIColor { traits in
                    switch traits.userInterfaceStyle {
                    case .dark:
                        return UIColor(dark)
                    default:
                        return UIColor(any)
                    }
                })
            #endif
        } else {
            self = any
        }
        #endif
    }
}

private extension EnvironmentValues {
    init(_ colorScheme: ColorScheme) {
        self.init()
        self.colorScheme = colorScheme
    }
}

#Preview("Semantic Color") {
    ScrollView {
        VStack {
            ForEach(SemanticColor.allCases) {
                ColorView(Color($0), description: $0.description)
            }
        }
        .padding()
    }
}

#Preview("Foundation Color") {
    ScrollView {
        VStack {
            ForEach(FoundationColor.allCases) {
                ColorView(Color($0), description: $0.description)
            }
        }
        .padding()
    }
}

private struct ColorView: View {
    let color: Color
    let description: (String, String)

    init(_ color: Color, description: String = "") {
        let components: [String] = description.components(separatedBy: ": ")
        self.description = (components[0], components.dropFirst().joined(separator: ": "))
        self.color = color
    }

    // MARK: View
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(color)
            VStack(alignment: .leading) {
                Text(description.0)
                    .bold()
                Text(description.1)
            }
            .font(.caption)
            .padding()
        }
        .frame(height: 88.0)
    }
}

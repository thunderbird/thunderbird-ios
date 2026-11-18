// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import BoltDesignSystem
import SwiftUI

extension View {

    /// Applies a Bolt shadow. Bolt doesn't use shadows in dark mode, where higher surfaces use lighter colors instead, so this does nothing there.
    public func shadow(_ shadow: Shadow) -> some View {
        modifier(ShadowModifier(shadow: shadow))
    }
}

private struct ShadowModifier: ViewModifier {
    let shadow: Shadow
    @Environment(\.colorScheme) private var colorScheme: ColorScheme

    // MARK: ViewModifier
    func body(content: Content) -> some View {
        if colorScheme == .dark || shadow.layers.isEmpty {
            content
        } else {
            shadow.layers.reduce(AnyView(content)) { view, layer in
                AnyView(view.shadow(color: .black.opacity(layer.opacity), radius: layer.radius, x: layer.x, y: layer.y))
            }
        }
    }
}

#Preview("Shadow") {
    ScrollView {
        VStack(spacing: 24.0) {
            ForEach(Shadow.allCases) { shadow in
                RoundedRectangle(cornerRadius: 12.0)
                    .fill(Color(.surface(.raised)))
                    .frame(height: 72.0)
                    .overlay(Text(shadow.description).padding())
                    .shadow(shadow)
            }
        }
        .font(.caption)
        .padding(24.0)
    }
    .background(Color(.surface(.base)))
}

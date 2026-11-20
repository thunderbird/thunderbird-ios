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
    // Both layers are always applied, so the content keeps its identity (state, focus, animations) when the shadow turns on or off.
    func body(content: Content) -> some View {
        content
            .shadow(color: color(0), radius: layer(0)?.radius ?? 0.0, x: layer(0)?.x ?? 0.0, y: layer(0)?.y ?? 0.0)
            .shadow(color: color(1), radius: layer(1)?.radius ?? 0.0, x: layer(1)?.x ?? 0.0, y: layer(1)?.y ?? 0.0)
    }

    /// The key (0) or ambient (1) layer; `nil` in dark mode or when the shadow doesn't have it.
    private func layer(_ index: Int) -> Shadow.Layer? {
        colorScheme != .dark && shadow.layers.indices.contains(index) ? shadow.layers[index] : nil
    }

    private func color(_ index: Int) -> Color {
        layer(index).map { .black.opacity($0.opacity) } ?? .clear
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

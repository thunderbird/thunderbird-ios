// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

#Preview("Icon") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88.0), spacing: 16.0)], spacing: 24.0) {
            ForEach(Icon.allCases) { icon in
                VStack(spacing: 8.0) {
                    Image(icon)
                        .font(.system(size: 32.0))
                    Text(icon.description)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
    }
}

#Preview("Icon Styles") {
    VStack(spacing: 24.0) {
        Label {
            Text("Hierarchical")
        } icon: {
            Image(Icon.addressBook)
        }
        Label {
            Text("Tinted")
        } icon: {
            Image(Icon.addressBookLock)
                .foregroundStyle(.tint)
        }
        Label {
            Text("Font size follows text")
        } icon: {
            Image(Icon.appMail)
        }
        .font(.largeTitle)
    }
    .font(.title)
    .padding()
}

#Preview("Icon Effects") {
    IconEffectsPreview()
}

private struct IconEffectsPreview: View {
    enum Effect: String, CaseIterable, Identifiable {
        case bounce, wiggle, rotate, pulse, scale, breathe

        // MARK: Identifiable
        var id: String { rawValue }
    }

    enum Rendering: String, CaseIterable, Identifiable {
        case hierarchical, monochrome, palette

        // MARK: Identifiable
        var id: String { rawValue }
    }

    @State private var effect: Effect = .bounce
    @State private var rendering: Rendering = .hierarchical
    @State private var trigger: Int = 0
    @State private var isActive: Bool = false

    private var isIndefinite: Bool { effect == .scale || effect == .breathe }

    // MARK: View
    var body: some View {
        VStack(spacing: 24.0) {
            Picker("Effect", selection: $effect) {
                ForEach(Effect.allCases) { effect in
                    Text(effect.rawValue).tag(effect)
                }
            }
            #if !os(watchOS)
            .pickerStyle(.segmented)
            #endif
            .onChange(of: effect) {
                isActive = false
            }
            Picker("Rendering", selection: $rendering) {
                ForEach(Rendering.allCases) { rendering in
                    Text(rendering.rawValue).tag(rendering)
                }
            }
            Button(isIndefinite ? (isActive ? "Stop" : "Start") : "Play") {
                if isIndefinite {
                    isActive.toggle()
                } else {
                    trigger += 1
                }
            }
            .buttonStyle(.borderedProminent)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64.0), spacing: 16.0)], spacing: 24.0) {
                ForEach(Icon.allCases) { icon in
                    rendered(animated(Image(icon)))
                        .font(.system(size: 32.0))
                }
            }
        }
        .padding()
    }

    @ViewBuilder
    private func rendered(_ view: some View) -> some View {
        switch rendering {
        case .hierarchical: view.symbolRenderingMode(.hierarchical)
        case .monochrome: view.symbolRenderingMode(.monochrome)
        case .palette: view.symbolRenderingMode(.palette).foregroundStyle(.primary, .secondary, .tint)
        }
    }

    @ViewBuilder
    private func animated(_ image: Image) -> some View {
        switch effect {
        case .bounce: image.symbolEffect(.bounce, value: trigger)
        case .wiggle: image.symbolEffect(.wiggle, value: trigger)
        case .rotate: image.symbolEffect(.rotate, value: trigger)
        case .pulse: image.symbolEffect(.pulse, value: trigger)
        case .scale: image.symbolEffect(.scale.up, isActive: isActive)
        case .breathe: image.symbolEffect(.breathe, isActive: isActive)
        }
    }
}

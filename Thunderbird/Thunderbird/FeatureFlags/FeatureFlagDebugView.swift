// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// Settings screen that lists the feature flags with a toggle for each, and a switch for whether remote settings apply.
///
/// Reached from Settings > Feature Flags. The link isn't limited to debug builds, so this screen is also shown in
/// release builds.
// TODO: Decide whether this screen should ship in release builds, and hide the Settings link if it shouldn't.
struct FeatureFlagDebugView: View {
    @Environment(FeatureFlags.self) private var flags: FeatureFlags
    @State private var allowRemoteFlags = false

    var body: some View {
        VStack {
            Toggle("all_remote_feature_flags", isOn: $allowRemoteFlags).padding()
            List(flags.featureList, id: \.self) { string in
                SettingRowView(string, flags.flagForKey(key: string))
            }
        }.onChange(of: allowRemoteFlags) {
            flags.setAllowRemoteFlags(allowRemote: allowRemoteFlags)
        }.task {
            allowRemoteFlags = flags.allowRemote
        }

    }
}

/// Row with a toggle that turns one feature flag on or off.
///
/// The toggle starts from the state passed in when the row is created and doesn't follow later changes to the flag,
/// such as remote settings arriving after the screen is shown.
// TODO: Verify on a device, and bind the toggle to `FeatureFlags.flagForKey(key:)` if rows don't update when remote
// settings arrive.
struct SettingRowView: View {
    init(_ flagName: String, _ onState: Bool) {

        self.flagName = flagName
        self.isOn = onState
    }

    @Environment(FeatureFlags.self) private var flags: FeatureFlags
    @State private var isOn: Bool
    private var flagName: String

    var body: some View {
        HStack {
            Toggle(flagName, isOn: $isOn)

        }.onChange(of: isOn) {
            flags.setFlagForKey(key: flagName, val: isOn)
        }
    }
}

#Preview("Feature Flag Settings") {
    @Previewable @State var flags: FeatureFlags = FeatureFlags(distribution: .current)

    FeatureFlagDebugView()
        .environment(flags)
}

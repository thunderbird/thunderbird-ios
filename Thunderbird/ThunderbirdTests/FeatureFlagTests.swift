// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Testing

struct FeatureFlagTests {
    @MainActor @Test func allowRemoteFlagsTest() {
        let allowRemote: Bool = FeatureFlags(distribution: .current).allowRemote  // Capture current setting
        FeatureFlags.resetAllowRemoteFlags()  // Reset to default value for test
        let flags: FeatureFlags = FeatureFlags(distribution: .current)
        #expect(flags.allowRemote == true)  // Expected default
        flags.setAllowRemoteFlags(allowRemote: false)
        #expect(flags.allowRemote == false)
        flags.setAllowRemoteFlags(allowRemote: allowRemote)  // Restore user setting
    }

    @MainActor @Test func flagForKeyTest() {
        FeatureFlags.resetFeatureFlags(distribution: .current)
        let flags: FeatureFlags = FeatureFlags(distribution: .current)
        #expect(flags.flagForKey(key: Flag.featureX.rawValue) == false)  // Expected default
        flags.setFlagForKey(key: Flag.featureX.rawValue, val: true)
        #expect(flags.flagForKey(key: Flag.featureX.rawValue) == true)
        FeatureFlags.resetFeatureFlags()
    }

    @MainActor @Test func setFlagForKeyTest() {
        FeatureFlags.resetFeatureFlags(distribution: .current)
        let flags: FeatureFlags = FeatureFlags(distribution: .current)
        #expect(flags.flagForKey(key: Flag.featureX.rawValue) == false)  // Expected default
        #expect(flags.flagForKey(key: Flag.featureY.rawValue) == false)  // Expected default
        flags.setFlagForKey(key: Flag.featureX.rawValue, val: true)
        #expect(flags.flagForKey(key: Flag.featureX.rawValue) == true)
        #expect(flags.flagForKey(key: Flag.featureY.rawValue) == false)
        flags.setFlagForKey(key: Flag.featureY.rawValue, val: true)
        #expect(flags.flagForKey(key: Flag.featureX.rawValue) == true)
        #expect(flags.flagForKey(key: Flag.featureY.rawValue) == true)
        flags.setFlagForKey(key: Flag.featureX.rawValue, val: false)
        #expect(flags.flagForKey(key: Flag.featureX.rawValue) == false)
        #expect(flags.flagForKey(key: Flag.featureY.rawValue) == true)
        FeatureFlags.resetFeatureFlags()
    }

    // MARK: Saved settings
    //
    // The tests below turn remote settings off first (see `withRemoteFlagsOff`), so they never touch the network.
    // They use the `.beta` and `.appstore` distributions, whose saved settings no other test writes to.

    //Expect: A flag that was turned on is still on in a new `FeatureFlags`, and flags that weren't touched stay off.
    //Case: When the flags are created again for the same distribution after a setting was saved.
    //Example: The user turns `fullDate` on in the debug screen, quits, and relaunches. The new instance reads the saved
    //  settings from `UserDefaults`, so `fullDate` is still on.
    @MainActor @Test func flagForKey_returnsSavedSetting_whenFlagsAreCreatedAgain() {
        withRemoteFlagsOff(resetting: [.beta]) {
            // Arrange
            let first = FeatureFlags(distribution: .beta)
            first.setFlagForKey(key: Flag.fullDate.rawValue, val: true)

            // Act
            let second = FeatureFlags(distribution: .beta)

            // Assert
            #expect(second.flagForKey(key: Flag.fullDate.rawValue) == true)
            #expect(second.flagForKey(key: Flag.featureX.rawValue) == false)
        }
    }

    //Expect: Turning a flag off saves the off state, so it stays off in a new `FeatureFlags`.
    //Case: When a flag was on, was turned off, and the flags are created again.
    //Example: Switching a flag back off must not leave the older `true` value behind in `UserDefaults`.
    @MainActor @Test func flagForKey_returnsFalse_whenSavedSettingWasTurnedOff() {
        withRemoteFlagsOff(resetting: [.beta]) {
            // Arrange
            let first = FeatureFlags(distribution: .beta)
            first.setFlagForKey(key: Flag.fullDate.rawValue, val: true)
            first.setFlagForKey(key: Flag.fullDate.rawValue, val: false)

            // Act
            let second = FeatureFlags(distribution: .beta)

            // Assert
            #expect(second.flagForKey(key: Flag.fullDate.rawValue) == false)
        }
    }

    //Expect: Each distribution keeps its own saved settings.
    //Case: When flags are turned on for one distribution and read back through another.
    //Example: Turning a flag on in a beta build must not turn it on in an App Store build.
    @MainActor @Test func flagForKey_isSeparatePerDistribution_whenSettingsAreSaved() {
        withRemoteFlagsOff(resetting: [.beta, .appstore]) {
            // Arrange
            let beta = FeatureFlags(distribution: .beta)
            let appStore = FeatureFlags(distribution: .appstore)

            // Act
            beta.setFlagForKey(key: Flag.featureX.rawValue, val: true)
            appStore.setFlagForKey(key: Flag.featureY.rawValue, val: true)

            // Assert
            let betaAgain = FeatureFlags(distribution: .beta)
            let appStoreAgain = FeatureFlags(distribution: .appstore)
            #expect(betaAgain.flagForKey(key: Flag.featureX.rawValue) == true)
            #expect(betaAgain.flagForKey(key: Flag.featureY.rawValue) == false)
            #expect(appStoreAgain.flagForKey(key: Flag.featureX.rawValue) == false)
            #expect(appStoreAgain.flagForKey(key: Flag.featureY.rawValue) == true)
        }
    }

    //Expect: Resetting one distribution's flags leaves the other distributions' flags alone.
    //Case: When `resetFeatureFlags(distribution:)` is called for one distribution while another has saved settings.
    //Example: Clearing the beta settings must not clear the App Store settings.
    @MainActor @Test func resetFeatureFlags_clearsOnlyThatDistribution_whenOthersHaveSettings() {
        withRemoteFlagsOff(resetting: [.beta, .appstore]) {
            // Arrange
            FeatureFlags(distribution: .beta).setFlagForKey(key: Flag.featureX.rawValue, val: true)
            FeatureFlags(distribution: .appstore).setFlagForKey(key: Flag.featureX.rawValue, val: true)

            // Act
            FeatureFlags.resetFeatureFlags(distribution: .beta)

            // Assert
            #expect(FeatureFlags(distribution: .beta).flagForKey(key: Flag.featureX.rawValue) == false)
            #expect(FeatureFlags(distribution: .appstore).flagForKey(key: Flag.featureX.rawValue) == true)
        }
    }

    // MARK: Allow remote

    //Expect: The saved allow-remote choice is what a new `FeatureFlags` reports, so a choice made in one launch applies
    //  in the next.
    //Case: When the allow-remote choice was saved as `false` and the flags are created again.
    @MainActor @Test func allowRemote_isFalse_whenSavedChoiceIsFalse() {
        withRemoteFlagsOff(resetting: [.beta]) {
            // Act
            let flags = FeatureFlags(distribution: .beta)

            // Assert
            #expect(flags.allowRemote == false)
        }
    }

    //Expect: `setAllowRemoteFlags` saves the choice, not only the in-memory value.
    //Case: When the choice is changed after the flags were created.
    //Example: Turning "all remote feature flags" on in the debug screen must still be on after a relaunch.
    @MainActor @Test func setAllowRemoteFlags_savesChoice_whenValueChanges() {
        withRemoteFlagsOff(resetting: [.beta]) {
            // Arrange
            let flags = FeatureFlags(distribution: .beta)

            // Act
            flags.setAllowRemoteFlags(allowRemote: true)

            // Assert
            #expect(flags.allowRemote == true)
            #expect(UserDefaults.standard.object(forKey: Self.allowRemoteKey) as? Bool == true)
        }
    }

    //Expect: Resetting removes the saved allow-remote choice, so the default (`true`) applies on the next launch.
    //Case: When `resetAllowRemoteFlags()` is called after a choice was saved.
    @MainActor @Test func resetAllowRemoteFlags_removesSavedChoice_whenChoiceWasSaved() {
        withRemoteFlagsOff(resetting: []) {
            // Act
            FeatureFlags.resetAllowRemoteFlags()

            // Assert
            #expect(UserDefaults.standard.object(forKey: Self.allowRemoteKey) == nil)
        }
    }

    // MARK: Helpers

    /// The `UserDefaults` key `FeatureFlags` saves the allow-remote choice under.
    private static let allowRemoteKey = "allowRemoteFeatureFlags"

    /// Run `body` with remote settings turned off, so creating a `FeatureFlags` doesn't download anything.
    ///
    /// The distributions' saved settings are cleared before and after, and the previous allow-remote choice is
    /// restored.
    ///
    /// - Parameters:
    ///   - distributions: The distributions whose saved settings the test uses.
    ///   - body: The test body.
    @MainActor private func withRemoteFlagsOff(resetting distributions: [Distribution], _ body: () -> Void) {
        let previous: Any? = UserDefaults.standard.object(forKey: Self.allowRemoteKey)
        UserDefaults.standard.set(false, forKey: Self.allowRemoteKey)
        distributions.forEach { FeatureFlags.resetFeatureFlags(distribution: $0) }
        defer {
            distributions.forEach { FeatureFlags.resetFeatureFlags(distribution: $0) }
            if let previous {
                UserDefaults.standard.set(previous, forKey: Self.allowRemoteKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.allowRemoteKey)
            }
        }
        body()
    }
}

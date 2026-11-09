// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

private let allowRemoteFlags = "allowRemoteFeatureFlags"

/// The names of the feature flags that the app code or tests check.
///
/// The raw value is the key a flag is saved under and the name used in the remote settings files.
public enum Flag: String {
    /// Placeholder flag with no behavior; only the tests and the remote settings files refer to it.
    // TODO: Replace the placeholder flags with real features, or remove them.
    case featureX
    /// Placeholder flag with no behavior; only the tests and the remote settings files refer to it.
    case featureY
    /// Show the full date in the email list instead of a smart date such as "1 day ago".
    case fullDate
}

/// On/off switches for features, combining built-in defaults, the user's saved choices and remote settings.
///
/// A flag is off unless something turns it on. When a ``Distribution``'s flags load, each one starts off, then saved
/// values replace the defaults, then (when ``allowRemote`` is `true` and the download succeeds) values from the
/// distribution's remote settings file replace the saved ones and are saved in turn. So a remote setting overrides a
/// flag the user turned on or off themselves, every time the app starts.
///
/// The settings live in `UserDefaults`, under a separate key for each distribution.
@MainActor
@Observable final public class FeatureFlags: Sendable {
    /// The flag names listed in ``FeatureFlagDebugView``.
    ///
    /// This list is written by hand and isn't derived from ``Flag``. A flag that is only in a remote settings file is
    /// saved and can be read, but isn't listed.
    // TODO: Derive this from ``Flag`` (make it `CaseIterable`) or the loaded settings, so a new flag can't be left out.
    public var featureList: [String] = ["fullDate", "featureX", "featureY"]
    //False = feature is turned off
    private var featureSettings: [String: Bool] = [:]
    /// Whether settings from the remote file are applied when the flags load. `true` until the user turns it off.
    public var allowRemote: Bool = true
    private var defaultsKey: String

    /// Load the saved settings for a distribution, then fetch its remote settings in the background if they're allowed.
    ///
    /// - Parameter distribution: The distribution whose saved settings and remote file are used.
    /// - Important: The remote settings arrive after this initializer returns, so a flag can change a moment later.
    // TODO: Replace the force casts here and in `setDefaultFlags(distribution:)` with conditional casts; a stored value
    // of another type crashes at launch.
    // Allow user to turn off/on feature flags pulled from Github
    public init(distribution: Distribution) {
        allowRemote = (UserDefaults.standard.value(forKey: allowRemoteFlags) ?? true) as! Bool
        defaultsKey = distribution.defaultsKey
        setDefaultFlags(distribution: distribution)
    }

    /// Set every listed flag off, apply the saved settings, then apply and save the remote settings if they're allowed.
    private func setDefaultFlags(distribution: Distribution) {
        featureSettings = featureList.reduce(
            into: [:],
            { (dict, key) in
                dict[key] = false
            })
        let storedSettings = (UserDefaults.standard.dictionary(forKey: defaultsKey) ?? [:]) as! [String: Bool]
        featureSettings.merge(storedSettings) { (current, new) in new }
        //if allowed to use url
        if allowRemote {
            Task {
                let remoteSettings: [String: Bool] = await getURLSettings(distribution: distribution)
                featureSettings.merge(remoteSettings) { (current, new) in new }
                UserDefaults.standard.setValue(featureSettings, forKey: defaultsKey)
            }
        }

    }

    /// Whether a flag is on.
    ///
    /// - Parameter key: The flag's name, such as `Flag.fullDate.rawValue`.
    /// - Returns: The flag's setting, or `false` if there's no setting for that name.
    public func flagForKey(key: String) -> Bool {
        return featureSettings[key] ?? false
    }
    /// Turn a flag on or off and save the settings for the current distribution.
    ///
    /// - Parameters:
    ///   - key: The flag's name.
    ///   - val: `true` to turn the flag on.
    /// - Note: If ``allowRemote`` is `true`, the remote file's value for this flag replaces the choice the next time
    ///   the flags load.
    public func setFlagForKey(key: String, val: Bool) {
        featureSettings[key] = val
        UserDefaults.standard.setValue(featureSettings, forKey: defaultsKey)
    }

    /// Save whether remote settings are applied.
    ///
    /// - Parameter allowRemote: `true` to apply remote settings.
    /// - Note: This takes effect the next time the flags load. Remote values already fetched and saved aren't undone.
    public func setAllowRemoteFlags(allowRemote: Bool) {
        self.allowRemote = allowRemote
        UserDefaults.standard.setValue(allowRemote, forKey: allowRemoteFlags)
    }

    /// Pull current feature flag settings from json URL based on current distribution
    /// Using JSON file in github for visibility
    ///
    /// - Parameter distribution: Selects which settings file to download from the project's GitHub Pages site.
    /// - Returns: The flags in the file, or an empty dictionary if the request fails or the response can't be decoded.
    ///   Errors are ignored.
    private func getURLSettings(distribution: Distribution) async -> [String: Bool] {
        var url: URL

        switch distribution {
        case .debug:
            url = URL(string: "https://thunderbird.github.io/thunderbird-ios/feature_flag_config_debug.json")!
        case .appstore:
            url = URL(string: "https://thunderbird.github.io/thunderbird-ios/feature_flag_config_appstore.json")!
        case .beta:
            url = URL(string: "https://thunderbird.github.io/thunderbird-ios/feature_flag_config_beta.json")!
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(Response.self, from: data)
            return response.flags
        } catch {
            return [:]
        }
    }

    /// Remove a distribution's saved flag settings, so its flags return to their defaults. Used by the tests.
    ///
    /// - Parameter distribution: The distribution whose saved settings are removed.
    static func resetFeatureFlags(distribution: Distribution = .current) {
        UserDefaults.standard.removeObject(forKey: distribution.defaultsKey)
    }

    /// Remove the saved allow-remote choice, so ``allowRemote`` goes back to `true` the next time the flags load.
    /// Used by the tests.
    static func resetAllowRemoteFlags() {
        UserDefaults.standard.removeObject(forKey: allowRemoteFlags)
    }
}

/// The JSON body of a remote settings file, such as `{"flags": {"fullDate": true}}`.
private struct Response: Decodable {
    let flags: [String: Bool]
}

/// Extends `Distribution` with the `UserDefaults` key that `FeatureFlags` saves its settings under.
private extension Distribution {
    var defaultsKey: String {
        switch self {
        case .debug: "featureListDebug"
        case .appstore: "featureListAppStore"
        case .beta: "featureListBeta"
        }
    }
}

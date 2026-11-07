// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// The channel a build is distributed through, used to pick which feature flag settings apply.
///
/// Each distribution saves its flag settings under its own key and loads its own remote settings file, so flags can be
/// on in beta builds and off in App Store builds. Use ``current`` for the running build.
public enum Distribution: Sendable {
    /// Development builds. Also the fallback when no other distribution's build setting is present.
    case debug
    /// Builds released through the App Store.
    case appstore
    /// Beta builds.
    case beta
}

/// Extends `Distribution` with the distribution that the running build was compiled as.
extension Distribution {
    /// The distribution selected by the build's `RELEASE` and `BETA` compilation conditions, or ``Distribution/debug``
    /// if neither is set.
    ///
    /// - Important: The project doesn't define `RELEASE` or `BETA` in its build settings, so every build, including
    ///   release builds, currently resolves to ``Distribution/debug``.
    // TODO: Define `RELEASE` and `BETA` in the Release and beta build configurations, so App Store and beta builds
    // don't use the debug flags.
    public static var current: Self {
        #if RELEASE
        return .appstore
        #elseif BETA
        return .beta
        #else
        return .debug
        #endif
    }
}

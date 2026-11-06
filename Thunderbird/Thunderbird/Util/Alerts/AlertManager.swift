// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The app's single shared state for an alert.
///
/// While alerts may have different UIs, we most likely won't want more than one on screen at a time. One manager for
/// the whole app prevents overlapping or hidden alerts and allows a unified format.
///
/// To raise an alert, set ``alertTitle`` and then set ``showAlert`` to `true`. 
/// This currently only triggers ``FeatureNotImplementedView`` alerts.
// TODO: Remove this manager together with `FeatureNotImplementedView` once the actions that raise it are implemented.
@MainActor
@Observable class AlertManager {
    /// The one instance. The initializer is private, so no other instance can exist.
    static let shared = AlertManager()

    /// Whether the alert is showing. Setting it back to `false` dismisses the alert.
    var showAlert: Bool = false
    /// The alert's title. ``FeatureNotImplementedView`` shows it as the name of the unfinished feature.
    var alertTitle: String?
    /// Intended body text for the alert. Nothing reads it yet.
    // TODO: Show this message in the alert, or remove it.
    var alertMessage: String?

    private init() {}  // Prevent creating multiple instances
}

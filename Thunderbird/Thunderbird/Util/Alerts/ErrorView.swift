// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Core
import SwiftUI

/// Extends `View` with the app's alert for errors reported on the account manager.
extension View {
    /// Show an alert whenever the account manager's `error` is set.
    ///
    /// The alert is titled "Error" and shows the error's description. Dismissing it clears the account manager's
    /// `error`.
    ///
    /// - Important: No view applies this modifier, so errors set on the account manager are never shown.
    // TODO: Apply `.error()` to the app's root view, so the errors the account screens report reach the user.
    func error() -> some View {
        modifier(ErrorView())
    }
}

/// Alert for the account manager's current error, applied with `View.error()`.
///
/// The message is the error's description, which isn't localized, or "An unknown error occurred" if the error was
/// cleared while the alert was still showing.
struct ErrorView: ViewModifier {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @State private var isPresented: Bool = false

    private var message: String {
        guard let error: Error = accountManager.error else {
            return "An unknown error occurred"
        }
        return "\(error)"
    }

    // MARK: ViewModifier
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $isPresented, actions: {}) {
                Text(message)
            }
            .onChange(of: accountManager.error, initial: true) {
                isPresented = accountManager.error != nil
            }
            .onChange(of: isPresented) {
                guard accountManager.error != nil, !isPresented else { return }
                accountManager.error = nil
            }
    }
}

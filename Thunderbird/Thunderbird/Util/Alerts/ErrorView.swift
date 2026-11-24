// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Core
import SwiftUI

/// Extends `View` with the app's alert for errors.
extension View {
    /// Show an alert whenever the account manager's `error` is set.
    ///
    /// The alert is titled "Error" and shows the error's description. Dismissing it clears the account manager's
    /// `error`.
    ///
    /// - Important: No view applies this modifier, so errors set on the account manager are never shown.
    // TODO: Apply `.error()` to the app's root view, so the errors the account screens report reach the user (#619).
    func error() -> some View {
        modifier(ErrorView())
    }

    /// Show an alert whenever `error` is set, for a view that keeps an error in its own state.
    ///
    /// The alert is titled "Error" and shows the error's description. Dismissing it sets `error` back to `nil`.
    func error(_ error: Binding<Error?>) -> some View {
        modifier(ErrorAlert(error: error))
    }
}

/// Alert for the account manager's current error, applied with `View.error()`. Drawn by ``ErrorAlert``.
struct ErrorView: ViewModifier {
    @Environment(AccountManager.self) private var accountManager: AccountManager

    private var error: Binding<Error?> {
        Binding(
            get: { accountManager.error },
            set: { accountManager.error = $0 as? AccountError })
    }

    // MARK: ViewModifier
    func body(content: Content) -> some View {
        content.modifier(ErrorAlert(error: error))
    }
}

/// Alert for an optional error, applied with `View.error(_:)`; the one place the app's error alert is drawn.
///
/// The message is the error's description, which isn't localized, or "An unknown error occurred" if the error was
/// cleared while the alert was still showing.
struct ErrorAlert: ViewModifier {
    @Binding var error: Error?

    private var isPresented: Binding<Bool> {
        Binding(
            get: { error != nil },
            set: { isPresented in
                if !isPresented { error = nil }
            })
    }

    // MARK: ViewModifier
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: isPresented, actions: {}) {
                Text(error.map { "\($0)" } ?? "An unknown error occurred")
            }
    }
}

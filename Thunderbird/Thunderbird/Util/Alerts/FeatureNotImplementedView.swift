// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A notice over the bottom of the screen that a feature isn't built yet, with an OK button to dismiss it.
///
/// As development progresses, buttons and features will appear incomplete. This is a stopgap that lets people see the
/// functionality and know that something isn't broken, just under construction.
///
/// `App` shows it while ``AlertManager`` is showing an alert. Its title is the alert's title, read once when the view
/// is created.
// TODO: Remove this view when the actions that raise it (Archive, Trash and More in the reader) are implemented.
struct FeatureNotImplementedView: View {
    init() {
        featureName = AlertManager.shared.alertTitle ?? ""
    }

    private var featureName: String

    // MARK: View
    var body: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()
            ZStack {
                VStack {
                    Text(featureName).font(.title)
                    Spacer()
                    Text("feature_not_implemented")
                    Spacer()
                    Button(action: {
                        AlertManager.shared.showAlert = false
                    }) {
                        Text("OK")
                    }.buttonStyle(.borderedProminent)
                }.padding(20)
            }
            .frame(height: 250)
            .frame(maxWidth: .infinity)
            .background(Color(white: 0.9))
            .cornerRadius(40)
            .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea()
    }
}

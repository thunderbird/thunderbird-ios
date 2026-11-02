// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import BoltUI
import SwiftUI

/// Manual setup step for choosing JMAP or IMAP before entering server details.
///
/// If neither option is selected, **Next** continues with JMAP.
struct EmailAccountTypeSelection: View {
    /// - Parameter path: Navigation path to push ``ManualServerSetup`` onto.
    init(_ path: Binding<NavigationPath>) {
        _path = path
    }

    @Binding private var path: NavigationPath
    @Environment(LoginDetails.self) private var loginDetails: LoginDetails
    @State private var selectedJMAP: Bool = false
    @State private var selectedIMAP: Bool = false

    // MARK: View
    var body: some View {
        Form {
            Text("account_server_settings_protocol_type_label").listRowSeparator(.hidden)
            Toggle(isOn: $selectedJMAP) {
                VStack(alignment: .leading) {
                    Text("jmap")
                    Text("jmap_text")
                }
            }
            .simultaneousGesture(
                TapGesture().onEnded {
                    selectedIMAP = false
                }
            )
            .fullToggleStyle()
            .listRowSeparator(.hidden)
            Toggle(isOn: $selectedIMAP) {
                VStack(alignment: .leading) {
                    Text("imap")
                    Text("imap_text")
                }
            }
            .simultaneousGesture(
                TapGesture().onEnded {
                    selectedJMAP = false
                }
            )
            .fullToggleStyle()
            .listRowSeparator(.hidden)
            VStack(alignment: HorizontalAlignment.leading) {
                Text("account_setup_tips").bold()
                Text("account_setup_imap_tip")
                Text("account_setup_jmap_tip")
            }
            .font(.caption)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.buttonFillOn)
                    .stroke(.gray, lineWidth: 1)
            }
        }
        .scrollContentBackground(.hidden)
        .listRowBackground(Color.clear)
        .navigationTitle("account_choose_email_type_label")
        .safeAreaInset(edge: .bottom) {
            Button(
                action: {
                    loginDetails.serverProtocol = selectedIMAP ? .imap : .jmap
                    path.append("ManualAccountSetup")

                }) {
                    Text("next_button")
                        .padding(5.5)
                        .frame(maxWidth: .infinity)
                }
                .tint(.blue)
                .padding()
                .buttonStyle(.borderedProminent)
        }
    }
}

#Preview("Outgoing Account Setup") {
    @Previewable @State var loginDetails: LoginDetails = LoginDetails()
    @Previewable @State var path: NavigationPath = NavigationPath()

    EmailAccountTypeSelection($path)
        .environment(loginDetails)
}

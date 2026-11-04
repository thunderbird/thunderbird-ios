// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Autoconfiguration
import SwiftUI

/// Button that looks up an email address's autoconfig settings, then shows the provider and source found, or the error.
///
/// Not currently shown in the app; it's only referenced by its preview.
// TODO: Delete this view, or show it in the app. Only its preview uses it.
struct AutoconfigView: View {
    /// Email address to look up.
    let emailAddress: String

    /// - Parameters:
    ///   - config: Set to the configuration found.
    ///   - emailAddress: Email address to look up. The button is disabled until it's a valid address.
    init(_ config: Binding<ClientConfig?>, for emailAddress: String) {
        self.emailAddress = emailAddress
        _config = config
    }

    @Binding private var config: ClientConfig?
    @State private var source: Source?
    @State private var error: Error?
    @State private var isSearching: Bool = false

    /// Whether the search button is enabled: the address is valid and no search is running.
    private var isEnabled: Bool { emailAddress.isEmailAddress && !isSearching }

    /// Look up the address with `URLSession.autoconfig(_:sources:queryMX:)`, storing the configuration and source, or the error.
    private func search() async {
        error = nil
        isSearching = true
        do {
            let autoconfig: (config: ClientConfig, source: Source) = try await URLSession.shared.autoconfig(emailAddress)
            isSearching = false
            config = autoconfig.config
            source = autoconfig.source
        } catch {
            isSearching = false
            self.error = error
        }
    }

    // MARK: View
    var body: some View {
        VStack {
            Button(action: {
                Task {
                    await search()
                }
            }) {
                HStack {
                    Spacer()
                    Label("Search Configurations", systemImage: "magnifyingglass")
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.accent)
            .disabled(!isEnabled)
            if let config {
                VStack(alignment: .leading) {
                    Label("Configuration found!", systemImage: "gearshape")
                        .font(.headline)
                    if let emailProvider = config.emailProvider {
                        Divider()
                        HStack {
                            Text("Provider:")
                                .bold()
                            Text(emailProvider.displayName)
                            Spacer()
                        }
                    }
                    if let source {
                        HStack {
                            Text("Source:")
                                .bold()
                            Text(source.description)
                            Spacer()
                        }
                    }
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 22.0)
                        .fill(.gray.opacity(0.2))
                }
            } else if let error {
                Label(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                    .padding()
            }
        }
        .overlay {
            ProgressView()
                .opacity(isSearching ? 1.0 : 0.0)
        }
    }
}

#Preview("Autoconfig View") {
    @Previewable @State var config: ClientConfig?

    AutoconfigView($config, for: "example@thunderbird.net")
        .padding()
}

/// Extends `String` with validation for text typed into email address fields.
extension String {
    /// Whether the string has a local part and a valid host, like `user@example.com`.
    ///
    /// This only checks the address's shape; it doesn't check that the address exists.
    var isEmailAddress: Bool { (try? host) != nil && (try? local) != nil }
}

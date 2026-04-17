import Autoconfiguration
import SwiftUI

struct AutoconfigView: View {
    let emailAddress: String

    init(_ config: Binding<ClientConfig?>, for emailAddress: String) {
        self.emailAddress = emailAddress
        _config = config
    }

    @Binding private var config: ClientConfig?
    @State private var source: Source?
    @State private var error: Error?
    @State private var isSearching: Bool = false

    private var isEnabled: Bool { emailAddress.isEmailAddress && !isSearching }

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

extension String {
    var isEmailAddress: Bool { (try? host) != nil && (try? local) != nil }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Bolt
import Core
import SwiftUI

/// The app's main screen: the list of emails, with a compose button and the account drawer.
///
/// The list shows the first account's emails, loaded when the view appears and again on pull-to-refresh. Selecting an
/// email pushes `ReadEmailView`, and the compose button pushes `ComposeView`. The menu button in the toolbar opens
/// `DrawerView`. `ContentView` presents this view once an account exists.
///
/// - Important: Until the account returns emails, the list shows `TempEmail.sampleData` placeholders. That includes
///   when loading fails, because the error is dropped, and when the account has no emails. Only the first account
///   in the `AccountManager` is shown.
struct EmailListView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @State private var emails: [Email] = []
    @State private var isRefreshing: Bool = false
    @State private var path: NavigationPath = NavigationPath()
    @State private var selections: Set<UUID> = []
    @State private var showDrawer: Bool = false
    #if os(iOS)
    @State private var editMode: EditMode = .inactive
    #endif

    /// Load the first account's emails into the list.
    ///
    /// Does nothing if there are no accounts. If loading throws, the error is dropped and the current list is kept.
    private func refresh() async {
        guard let account: Account = accountManager.allAccounts.first else { return }
        isRefreshing = true
        if let emails: [Email] = try? await account.emails() {
            self.emails = emails
        }
        isRefreshing = false
    }

    // MARK: View
    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottomTrailing) {
                if !emails.isEmpty {
                    VStack {
                        List(emails, id: \.id, selection: $selections) { email in
                            NavigationLink(destination: {
                                ReadEmailView(email)
                            }) {
                                EmailCellView(email: email)
                            }
                            .listRowSeparator(.hidden)
                            .navigationLinkIndicatorVisibility(.hidden)
                            .accessibilityHidden(showDrawer)
                        }
                        .listStyle(.plain)
                    }
                    .refreshable {
                        await refresh()
                    }
                } else {
                    VStack {
                        List(TempEmail.sampleData, id: \.uuid, selection: $selections) { email in
                            NavigationLink(destination: {
                                ReadEmailView(email)
                            }) {
                                EmailCellView(email: email)
                            }
                            .listRowSeparator(.hidden)
                            .navigationLinkIndicatorVisibility(.hidden)
                            .accessibilityHidden(showDrawer)
                        }
                        .listStyle(.plain)
                    }
                    .refreshable {
                        await refresh()
                    }
                }
                Button {
                    path.append("compose")
                } label: {
                    Image("compose")
                        .font(.title.weight(.regular))
                        .padding(.all, 12)
                        .padding(.leading, 5)
                        .background(Color(white: 0.9))
                        .foregroundColor(.muted)
                        .clipShape(Circle())
                }.background(.clear)
                    .accessibilityHidden(showDrawer)
                    .padding()
                    .navigationDestination(for: String.self) { destination in
                        if destination == "compose" {
                            ComposeView()
                        }
                    }
                DrawerView(showDrawer: $showDrawer)
                    .accessibilityHidden(!showDrawer)
            }
            .navigationTitle("inbox_header")
            .toolbar {
                ToolbarItem(placement: .leading) {
                    Button {
                        showDrawer = true
                    } label: {
                        Label("Account", systemImage: "line.3.horizontal").labelStyle(.iconOnly)
                    }.accessibilityHidden(showDrawer)
                }
            }
            .task {
                await refresh()
            }
        }
    }
}

#Preview("Email List View") {
    @Previewable @State var flags: FeatureFlags = FeatureFlags(distribution: .current)
    @Previewable @State var accountManager: AccountManager = AccountManager()

    EmailListView()
        .environment(accountManager)
        .environment(flags)
}

/// Extends `ToolbarItemPlacement` with platform-appropriate toolbar placements for the email list.
private extension ToolbarItemPlacement {
    static var leading: Self {
        #if os(iOS)
        .topBarLeading
        #else
        .automatic
        #endif
    }

    static var trailing: Self {
        #if os(iOS)
        .topBarTrailing
        #else
        .automatic
        #endif
    }
}

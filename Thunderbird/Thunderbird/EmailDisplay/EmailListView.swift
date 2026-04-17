//
//  EmailListView.swift
//  Thunderbird
//
//  Created by Ashley Soucar on 10/20/25.
//

import SwiftUI
import Account

struct EmailListView: View {
    @Environment(Accounts.self) private var accounts: Accounts
    @Environment(\.openURL) private var openURL
    let tempEmails = TempEmail.sampleData
    #if os(iOS)
    @State var editMode: EditMode = .inactive
    #endif
    @State private var selections = Set<UUID>()

    //Hardcoded for testing
    let attributedString = try? NSMutableAttributedString(
        data: Data(
            """
            <html>
            <body>
            <h2>This is a test email with a bit of text</h2>
            <p>Its doing its best to model how an email might look</p>
            </body>
            </html>
            """.utf8),
        options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil
    )

    func sortEmails() {
        //Not yet implemented
        AlertManager.shared.showAlert = true
        AlertManager.shared.alertTitle = "Sort Emails"
    }

    func selectAll() {
        for tempEmail in tempEmails {
            selections.insert(tempEmail.uuid)
        }
    }
    //TODO: replace with backend unread state call
    func markAllRead() {
        for tempEmail in tempEmails {
            tempEmail.unread = false
            tempEmail.newEmail = false
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                if tempEmails.isEmpty {
                    VStack {
                        Text("empty_inbox")
                            .padding(.bottom, 5)
                        Text("new_messages_will_appear")
                            .padding(.bottom, 10)
                        Button {
                            //Do Nothing
                        } label: {
                            Text("add_another_account")
                        }.buttonBorderShape(.capsule)
                            .buttonStyle(.bordered)
                            .foregroundStyle(.black)
                        Spacer()
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack {
                        List(tempEmails, id: \.uuid, selection: $selections) { email in
                            EmailCellView(email: email)
                                .listRowSeparator(.hidden)
                                #if os(iOS)
                            .onLongPressGesture {
                                withAnimation {
                                    editMode = .active
                                }
                            }
                                #endif
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    #if os(iOS)
                    .environment(\.editMode, $editMode)
                    #endif
                }
                Button {
                    // Action
                } label: {
                    Image("compose")
                        .font(.title.weight(.regular))
                        .padding(.all, 12)
                        .padding(.leading, 5)
                        .background(Color(white: 0.9))
                        .foregroundColor(.muted)
                        .clipShape(Circle())
                }
                .background(.clear)
                .padding()
                .disabled(true)
            }
            .navigationTitle("inbox_header")
            #if os(iOS)
            .navigationBarBackButtonHidden(editMode.isEditing)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .cancellationAction) {
                    if editMode.isEditing == true {
                        Button(
                            "close_button", systemImage: "xmark",
                            action: {
                                withAnimation {
                                    editMode = .inactive
                                }
                            })
                    }
                }
                #endif
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(
                            "date_sort_button",
                            action: {
                                sortEmails()
                            })
                        Button(
                            "read_status_sort_button",
                            action: {
                                sortEmails()
                            })
                        Button(
                            "has_attachments_sort_button",
                            action: {
                                sortEmails()
                            })
                    } label: {
                        Label("sort_button", systemImage: "line.3.horizontal.decrease", )
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        #if os(iOS)
                        Button(
                            editMode.isEditing ? "done_button" : "select_all_button",
                            action: {
                                withAnimation {
                                    editMode = editMode.isEditing ? .inactive : .active
                                }
                                selectAll()
                            })
                        #endif
                        Button(
                            "mark_all_read_button",
                            action: {
                                markAllRead()
                            })
                        Button(
                            "account_sign_out_button",
                            action: {
                                accounts.deleteAccounts()
                            })
                        Button(
                            "donation_support",
                            action: {
                                guard let url = URL(string: "https://www.thunderbird.net/en-US/donate/") else { return }
                                openURL(url)
                            })
                    } label: {
                        Label("options_button", systemImage: "ellipsis")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink("settings_button", destination: FeatureFlagDebugView())
                }
            }
        }

    }
}

#Preview("Email List") {
    @Previewable @State var accounts: Accounts = Accounts()
    EmailListView().environment(accounts)

}

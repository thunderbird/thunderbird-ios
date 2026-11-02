// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Bolt
import Core
import SwiftUI

/// Runs the account's connection tests and lists each result as it arrives.
///
/// Testing starts half a second after the view appears, with a short pause between tests.
struct AccountTestView: View {
    /// Account being tested.
    let account: Account

    /// - Parameter account: Account to test.
    init(_ account: Account) {
        self.account = account
    }

    @State private var results: [TestResult] = []
    @State private var isTesting: Bool = false

    // MARK: View
    var body: some View {
        VStack {
            ContentUnavailableView("\(account.name)", systemImage: "stethoscope")
            ForEach(results) { result in
                HStack {
                    Text(result.description)
                    Spacer()
                    Image(systemName: result.isFailure ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(result.isFailure ? .red : .green)
                }
            }
            HStack {
                Text("Testing…")
                Spacer()
                ProgressView()
            }
            .opacity(isTesting ? 1.0 : 0.0)
        }
        .padding()
        .task {
            try? await Task.sleep(for: .milliseconds(500))
            isTesting = true
            for await result in account.test(sleep: .milliseconds(200)) {
                results.append(result)
            }
            isTesting = false
        }
    }
}

#Preview("Account Test View") {
    AccountTestView(Account())
}

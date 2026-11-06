// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import MIME

/// Decode HTML entities on another thread, giving up after a few seconds, so a decoder that never returns fails the
/// test and doesn't hang the test run.
func decodedWithinTimeLimit(_ text: String, seconds: Double = 5) async -> String? {
    await withCheckedContinuation { continuation in
        let resumer: ResumeOnce = ResumeOnce(continuation)
        DispatchQueue.global().async {
            resumer.resume(text.htmlEntitiesDecoded())
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + seconds) {
            resumer.resume(nil)
        }
    }
}

/// Resumes a continuation with the first value it's given and ignores later ones.
private final class ResumeOnce: @unchecked Sendable {
    init(_ continuation: CheckedContinuation<String?, Never>) {
        self.continuation = continuation
    }

    func resume(_ value: String?) {
        lock.lock()
        defer { lock.unlock() }
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(returning: value)
    }

    private var continuation: CheckedContinuation<String?, Never>?
    private let lock: NSLock = NSLock()
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import BoltUI
import SwiftUI
import Testing

struct ColorTests {
    @Test func isDynamic() {
        #expect(
            Color(SemanticColor.warning(.default)).isDynamic == true)
        #expect(
            Color(FoundationColor(.ink700)).isDynamic == false)
    }

    @Test func resolveForColorScheme() {
        #expect(
            Color(SemanticColor.warning(.default)).resolve(for: .light).linearRed == 0.9559735)
        #expect(
            Color(SemanticColor.warning(.default)).resolve(for: .dark).linearRed == 0.9911022)

        #expect(
            Color(FoundationColor(.ink700)).resolve(for: .light).linearRed == 0.15592647)
        #expect(
            Color(FoundationColor(.ink700)).resolve(for: .dark).linearRed == 0.15592647)
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import BoltUI
import SwiftUI
import Testing

struct ColorTests {
    @Test func isDynamic() {
        #expect(
            SemanticColor.allCases.compactMap {
                $0.id == "semantic.warning.default" ? Color($0) : nil
            }.first?.isDynamic == true)
        #expect(
            FoundationColor.allCases.compactMap {
                $0.id == "foundation.ink.700" ? Color($0) : nil
            }.first?.isDynamic == false)
    }

    @Test func resolveForColorScheme() {
        #expect(
            SemanticColor.allCases.compactMap {
                $0.id == "semantic.warning.default" ? Color($0) : nil
            }.first?.resolve(for: .light).linearRed == 0.9559735)
        #expect(
            SemanticColor.allCases.compactMap {
                $0.id == "semantic.warning.default" ? Color($0) : nil
            }.first?.resolve(for: .dark).linearRed == 0.9911022)

        #expect(
            FoundationColor.allCases.compactMap {
                $0.id == "foundation.ink.700" ? Color($0) : nil
            }.first?.resolve(for: .light).linearRed == 0.15592647)
        #expect(
            FoundationColor.allCases.compactMap {
                $0.id == "foundation.ink.700" ? Color($0) : nil
            }.first?.resolve(for: .dark).linearRed == 0.15592647)
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

extension View {

    /// Add view padding according to Bolt spacing density.
    public func padding(_ edges: Edge.Set = .all, density: CGFloat.Density) -> some View {
        padding(edges, .padding(density))
    }
}
extension CGFloat {
    public enum Density: Double, CaseIterable, CustomStringConvertible {
        case relaxed = 1.5
        case `default` = 1.0
        case compact = 0.5

        // MARK: CustomStringConvertible
        public var description: String {
            switch self {
            case .relaxed: "relaxed"
            case .default: "default"
            case .compact: "compact"
            }
        }
    }

    /// Corner radius for Bolt surfaces such as cards, selected rows and pills.
    public static let cornerRadius: Self = 24.0

    public static func padding(_ density: Density = .default) -> Self {
        density.rawValue * 16.0
    }

    public static func spacing(_ density: Density = .default) -> Self {
        density.rawValue * 24.0
    }
}

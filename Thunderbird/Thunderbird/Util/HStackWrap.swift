// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A layout that places its subviews left to right and starts a new row when the next one doesn't fit.
///
/// SwiftUI has no wrapping horizontal stack, so this fills the gap. Each subview keeps its own ideal size, and a row
/// wraps when adding the next subview would pass the available width.
// TODO: Verify with rows of different heights. `placeSubviews(in:proposal:subviews:cache:)` moves down by the height of
// the view that starts the next row, while `sizeThatFits(proposal:subviews:cache:)` uses the tallest view in each row.
// Also check a first subview that is wider than the container, which looks like it's pushed down a row.
struct HStackWrap: Layout {
    private let horizontalSpacing: CGFloat
    private let verticalSpacing: CGFloat

    /// - Parameters:
    ///   - horizontalSpacing: Space between subviews in a row, in points. Defaults to 6.
    ///   - verticalSpacing: Space between rows, in points. Defaults to 5.
    public init(
        horizontalSpacing: CGFloat = 6,
        verticalSpacing: CGFloat = 5
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        var width = 0.0
        var height = 0.0
        var rowHeight = 0.0
        var rowWidth = 0.0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if rowWidth + size.width > maxWidth {
                width = max(rowWidth, maxWidth)
                height += rowHeight + verticalSpacing
                rowWidth = 0
                rowHeight = 0
            }

            rowWidth += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }

        width = max(width, rowWidth)
        height += rowHeight

        return CGSize(width: width, height: height)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        let maxWidth = bounds.maxX

        for subview in subviews {
            let size = subview.dimensions(in: .unspecified)

            if currentX + size.width > maxWidth {
                currentY += size.height + verticalSpacing
                currentX = bounds.minX
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: .unspecified
            )

            currentX += size.width + horizontalSpacing
        }
    }
}

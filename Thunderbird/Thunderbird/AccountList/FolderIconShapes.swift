// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// The folder icons, created once so views can pick one by name.
///
/// Each kind has a plain version and a `Tinted` version drawn in the accent color. `iconSwitcher(folderName:tinted:)`
/// chooses among them.
struct FolderIconShapes {
    public let inboxPath = InboxIcon()
    public let draftPath = DraftIcon()
    public let sentPath = SentIcon()
    public let archivePath = ArchiveIcon()
    public let spamPath = SpamIcon()
    public let trashPath = TrashIcon()
    public let folderPath = FolderIcon()
    public let inboxPathTinted = InboxIcon(tinted: true)
    public let draftPathTinted = DraftIcon(tinted: true)
    public let sentPathTinted = SentIcon(tinted: true)
    public let archivePathTinted = ArchiveIcon(tinted: true)
    public let spamPathTinted = SpamIcon(tinted: true)
    public let trashPathTinted = TrashIcon(tinted: true)
    public let folderPathTinted = FolderIcon(tinted: true)

}

/// The icon for an inbox tray, drawn as two stacked layers: a solid shape and a second shape at 20% opacity.
struct InboxIcon: View {
    /// Whether to draw the icon in the accent color instead of black.
    var tinted: Bool = false
    var body: some View {
        ZStack {
            ZStack {
                ZStack {
                    Layer0().fill(tinted ? .accent : .black).stroke(tinted ? .accent : .clear)
                }
                ZStack {
                    Layer1().fill(tinted ? .accent : .black).stroke(tinted ? .accent : .clear)
                }
                .compositingGroup()
                .opacity(0.2)
            }
        }
    }

    private struct Layer0: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width = rect.size.width
            let height = rect.size.height
            path.move(to: CGPoint(x: 0.75 * width, y: 0.08333 * height))
            path.addCurve(to: CGPoint(x: 0.91667 * width, y: 0.25 * height), control1: CGPoint(x: 0.84196 * width, y: 0.08333 * height), control2: CGPoint(x: 0.91667 * width, y: 0.15804 * height))
            path.addLine(to: CGPoint(x: 0.91667 * width, y: 0.75 * height))
            path.addCurve(to: CGPoint(x: 0.75 * width, y: 0.91667 * height), control1: CGPoint(x: 0.91667 * width, y: 0.84196 * height), control2: CGPoint(x: 0.84196 * width, y: 0.91667 * height))
            path.addLine(to: CGPoint(x: 0.25 * width, y: 0.91667 * height))
            path.addCurve(to: CGPoint(x: 0.08333 * width, y: 0.75 * height), control1: CGPoint(x: 0.15804 * width, y: 0.91667 * height), control2: CGPoint(x: 0.08333 * width, y: 0.84196 * height))
            path.addLine(to: CGPoint(x: 0.08333 * width, y: 0.25 * height))
            path.addCurve(to: CGPoint(x: 0.25 * width, y: 0.08333 * height), control1: CGPoint(x: 0.08333 * width, y: 0.15804 * height), control2: CGPoint(x: 0.15804 * width, y: 0.08333 * height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.25 * width, y: 0.125 * height))
            path.addQuadCurve(to: CGPoint(x: 0.22462 * width, y: 0.1275 * height), control: CGPoint(x: 0.23692 * width, y: 0.125 * height))
            path.addCurve(to: CGPoint(x: 0.12754 * width, y: 0.22458 * height), control1: CGPoint(x: 0.17563 * width, y: 0.1373 * height), control2: CGPoint(x: 0.13734 * width, y: 0.17559 * height))
            path.addLine(to: CGPoint(x: 0.12754 * width, y: 0.22479 * height))
            path.addQuadCurve(to: CGPoint(x: 0.12567 * width, y: 0.23713 * height), control: CGPoint(x: 0.12629 * width, y: 0.23083 * height))
            path.addLine(to: CGPoint(x: 0.12567 * width, y: 0.23721 * height))
            path.addCurve(to: CGPoint(x: 0.125 * width, y: 0.25 * height), control1: CGPoint(x: 0.12523 * width, y: 0.24146 * height), control2: CGPoint(x: 0.125 * width, y: 0.24573 * height))
            path.addLine(to: CGPoint(x: 0.125 * width, y: 0.5 * height))
            path.addLine(to: CGPoint(x: 0.16667 * width, y: 0.5 * height))
            path.addLine(to: CGPoint(x: 0.16667 * width, y: 0.41667 * height))
            path.addCurve(to: CGPoint(x: 0.20833 * width, y: 0.34463 * height), control1: CGPoint(x: 0.16667 * width, y: 0.386 * height), control2: CGPoint(x: 0.1835 * width, y: 0.35917 * height))
            path.addLine(to: CGPoint(x: 0.20833 * width, y: 0.29167 * height))
            path.addCurve(to: CGPoint(x: 0.29167 * width, y: 0.20833 * height), control1: CGPoint(x: 0.20833 * width, y: 0.24583 * height), control2: CGPoint(x: 0.24583 * width, y: 0.20833 * height))
            path.addLine(to: CGPoint(x: 0.70833 * width, y: 0.20833 * height))
            path.addCurve(to: CGPoint(x: 0.79167 * width, y: 0.29167 * height), control1: CGPoint(x: 0.75417 * width, y: 0.20833 * height), control2: CGPoint(x: 0.79167 * width, y: 0.24583 * height))
            path.addLine(to: CGPoint(x: 0.79167 * width, y: 0.34463 * height))
            path.addCurve(to: CGPoint(x: 0.83333 * width, y: 0.41667 * height), control1: CGPoint(x: 0.8165 * width, y: 0.35912 * height), control2: CGPoint(x: 0.83333 * width, y: 0.386 * height))
            path.addLine(to: CGPoint(x: 0.83333 * width, y: 0.5 * height))
            path.addLine(to: CGPoint(x: 0.875 * width, y: 0.5 * height))
            path.addLine(to: CGPoint(x: 0.875 * width, y: 0.25 * height))
            path.addQuadCurve(to: CGPoint(x: 0.87246 * width, y: 0.22462 * height), control: CGPoint(x: 0.875 * width, y: 0.23692 * height))
            path.addCurve(to: CGPoint(x: 0.77537 * width, y: 0.12754 * height), control1: CGPoint(x: 0.86266 * width, y: 0.17563 * height), control2: CGPoint(x: 0.82437 * width, y: 0.13734 * height))
            path.addLine(to: CGPoint(x: 0.77521 * width, y: 0.12754 * height))
            path.addQuadCurve(to: CGPoint(x: 0.76287 * width, y: 0.12567 * height), control: CGPoint(x: 0.76917 * width, y: 0.12629 * height))
            path.addLine(to: CGPoint(x: 0.76279 * width, y: 0.12567 * height))
            path.addQuadCurve(to: CGPoint(x: 0.75 * width, y: 0.125 * height), control: CGPoint(x: 0.7565 * width, y: 0.125 * height))
            path.addLine(to: CGPoint(x: 0.25 * width, y: 0.125 * height))
            path.move(to: CGPoint(x: 0.29167 * width, y: 0.25 * height))
            path.addCurve(to: CGPoint(x: 0.25 * width, y: 0.29167 * height), control1: CGPoint(x: 0.26821 * width, y: 0.25 * height), control2: CGPoint(x: 0.25 * width, y: 0.26821 * height))
            path.addLine(to: CGPoint(x: 0.25 * width, y: 0.33333 * height))
            path.addLine(to: CGPoint(x: 0.75 * width, y: 0.33333 * height))
            path.addLine(to: CGPoint(x: 0.75 * width, y: 0.29167 * height))
            path.addCurve(to: CGPoint(x: 0.70833 * width, y: 0.25 * height), control1: CGPoint(x: 0.75 * width, y: 0.26821 * height), control2: CGPoint(x: 0.73179 * width, y: 0.25 * height))
            path.addLine(to: CGPoint(x: 0.29167 * width, y: 0.25 * height))
            path.move(to: CGPoint(x: 0.25 * width, y: 0.375 * height))
            path.addCurve(to: CGPoint(x: 0.20833 * width, y: 0.41667 * height), control1: CGPoint(x: 0.22654 * width, y: 0.375 * height), control2: CGPoint(x: 0.20833 * width, y: 0.39321 * height))
            path.addLine(to: CGPoint(x: 0.20833 * width, y: 0.5 * height))
            path.addLine(to: CGPoint(x: 0.35417 * width, y: 0.5 * height))
            path.addCurve(to: CGPoint(x: 0.375 * width, y: 0.52083 * height), control1: CGPoint(x: 0.36567 * width, y: 0.5 * height), control2: CGPoint(x: 0.375 * width, y: 0.50933 * height))
            path.addLine(to: CGPoint(x: 0.375 * width, y: 0.54167 * height))
            path.addCurve(to: CGPoint(x: 0.5 * width, y: 0.66667 * height), control1: CGPoint(x: 0.375 * width, y: 0.61096 * height), control2: CGPoint(x: 0.43071 * width, y: 0.66667 * height))
            path.addCurve(to: CGPoint(x: 0.625 * width, y: 0.54167 * height), control1: CGPoint(x: 0.56929 * width, y: 0.66667 * height), control2: CGPoint(x: 0.625 * width, y: 0.61096 * height))
            path.addLine(to: CGPoint(x: 0.625 * width, y: 0.52083 * height))
            path.addCurve(to: CGPoint(x: 0.64583 * width, y: 0.5 * height), control1: CGPoint(x: 0.625 * width, y: 0.50933 * height), control2: CGPoint(x: 0.63433 * width, y: 0.5 * height))
            path.addLine(to: CGPoint(x: 0.79167 * width, y: 0.5 * height))
            path.addLine(to: CGPoint(x: 0.79167 * width, y: 0.41667 * height))
            path.addCurve(to: CGPoint(x: 0.75 * width, y: 0.375 * height), control1: CGPoint(x: 0.79167 * width, y: 0.39321 * height), control2: CGPoint(x: 0.77346 * width, y: 0.375 * height))
            path.addLine(to: CGPoint(x: 0.25 * width, y: 0.375 * height))
            path.move(to: CGPoint(x: 0.125 * width, y: 0.75 * height))
            path.addCurve(to: CGPoint(x: 0.12562 * width, y: 0.76279 * height), control1: CGPoint(x: 0.12499 * width, y: 0.75427 * height), control2: CGPoint(x: 0.1252 * width, y: 0.75854 * height))
            path.addLine(to: CGPoint(x: 0.12563 * width, y: 0.76288 * height))
            path.addCurve(to: CGPoint(x: 0.1275 * width, y: 0.77521 * height), control1: CGPoint(x: 0.12604 * width, y: 0.76701 * height), control2: CGPoint(x: 0.12667 * width, y: 0.77113 * height))
            path.addLine(to: CGPoint(x: 0.1275 * width, y: 0.77542 * height))
            path.addCurve(to: CGPoint(x: 0.22458 * width, y: 0.8725 * height), control1: CGPoint(x: 0.1373 * width, y: 0.82441 * height), control2: CGPoint(x: 0.17559 * width, y: 0.8627 * height))
            path.addLine(to: CGPoint(x: 0.22479 * width, y: 0.8725 * height))
            path.addCurve(to: CGPoint(x: 0.25 * width, y: 0.875 * height), control1: CGPoint(x: 0.23309 * width, y: 0.87418 * height), control2: CGPoint(x: 0.24153 * width, y: 0.87502 * height))
            path.addLine(to: CGPoint(x: 0.75 * width, y: 0.875 * height))
            path.addQuadCurve(to: CGPoint(x: 0.77542 * width, y: 0.8725 * height), control: CGPoint(x: 0.76312 * width, y: 0.875 * height))
            path.addCurve(to: CGPoint(x: 0.8725 * width, y: 0.77542 * height), control1: CGPoint(x: 0.82441 * width, y: 0.8627 * height), control2: CGPoint(x: 0.8627 * width, y: 0.82441 * height))
            path.addQuadCurve(to: CGPoint(x: 0.875 * width, y: 0.75 * height), control: CGPoint(x: 0.875 * width, y: 0.76313 * height))
            path.addLine(to: CGPoint(x: 0.875 * width, y: 0.54167 * height))
            path.addLine(to: CGPoint(x: 0.66667 * width, y: 0.54167 * height))
            path.addCurve(to: CGPoint(x: 0.5 * width, y: 0.70833 * height), control1: CGPoint(x: 0.66667 * width, y: 0.63346 * height), control2: CGPoint(x: 0.59179 * width, y: 0.70833 * height))
            path.addCurve(to: CGPoint(x: 0.33333 * width, y: 0.54167 * height), control1: CGPoint(x: 0.40821 * width, y: 0.70833 * height), control2: CGPoint(x: 0.33333 * width, y: 0.63346 * height))
            path.addLine(to: CGPoint(x: 0.125 * width, y: 0.54167 * height))
            path.closeSubpath()
            return path
        }
    }

    private struct Layer1: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width = rect.size.width
            let height = rect.size.height
            path.move(to: CGPoint(x: 0.75 * width, y: 0.10417 * height))
            path.addCurve(to: CGPoint(x: 0.89583 * width, y: 0.25 * height), control1: CGPoint(x: 0.83079 * width, y: 0.10417 * height), control2: CGPoint(x: 0.89583 * width, y: 0.16921 * height))
            path.addLine(to: CGPoint(x: 0.89583 * width, y: 0.75 * height))
            path.addCurve(to: CGPoint(x: 0.75 * width, y: 0.89583 * height), control1: CGPoint(x: 0.89583 * width, y: 0.83079 * height), control2: CGPoint(x: 0.83079 * width, y: 0.89583 * height))
            path.addLine(to: CGPoint(x: 0.25 * width, y: 0.89583 * height))
            path.addCurve(to: CGPoint(x: 0.10417 * width, y: 0.75 * height), control1: CGPoint(x: 0.16921 * width, y: 0.89583 * height), control2: CGPoint(x: 0.10417 * width, y: 0.83079 * height))
            path.addLine(to: CGPoint(x: 0.10417 * width, y: 0.25 * height))
            path.addCurve(to: CGPoint(x: 0.14676 * width, y: 0.14676 * height), control1: CGPoint(x: 0.10406 * width, y: 0.21129 * height), control2: CGPoint(x: 0.11938 * width, y: 0.17413 * height))
            path.addCurve(to: CGPoint(x: 0.25 * width, y: 0.10417 * height), control1: CGPoint(x: 0.17413 * width, y: 0.11938 * height), control2: CGPoint(x: 0.21129 * width, y: 0.10406 * height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.29167 * width, y: 0.22917 * height))
            path.addCurve(to: CGPoint(x: 0.22917 * width, y: 0.29167 * height), control1: CGPoint(x: 0.25704 * width, y: 0.22917 * height), control2: CGPoint(x: 0.22917 * width, y: 0.25704 * height))
            path.addLine(to: CGPoint(x: 0.22917 * width, y: 0.35775 * height))
            path.addCurve(to: CGPoint(x: 0.1875 * width, y: 0.41667 * height), control1: CGPoint(x: 0.20488 * width, y: 0.36629 * height), control2: CGPoint(x: 0.1875 * width, y: 0.38938 * height))
            path.addLine(to: CGPoint(x: 0.1875 * width, y: 0.52083 * height))
            path.addLine(to: CGPoint(x: 0.35417 * width, y: 0.52083 * height))
            path.addLine(to: CGPoint(x: 0.35417 * width, y: 0.54167 * height))
            path.addCurve(to: CGPoint(x: 0.39676 * width, y: 0.64491 * height), control1: CGPoint(x: 0.35406 * width, y: 0.58038 * height), control2: CGPoint(x: 0.36938 * width, y: 0.61754 * height))
            path.addCurve(to: CGPoint(x: 0.5 * width, y: 0.6875 * height), control1: CGPoint(x: 0.42413 * width, y: 0.67228 * height), control2: CGPoint(x: 0.46129 * width, y: 0.68761 * height))
            path.addCurve(to: CGPoint(x: 0.64583 * width, y: 0.54167 * height), control1: CGPoint(x: 0.58079 * width, y: 0.6875 * height), control2: CGPoint(x: 0.64583 * width, y: 0.62246 * height))
            path.addLine(to: CGPoint(x: 0.64583 * width, y: 0.52083 * height))
            path.addLine(to: CGPoint(x: 0.8125 * width, y: 0.52083 * height))
            path.addLine(to: CGPoint(x: 0.8125 * width, y: 0.41667 * height))
            path.addCurve(to: CGPoint(x: 0.77083 * width, y: 0.35775 * height), control1: CGPoint(x: 0.8125 * width, y: 0.38938 * height), control2: CGPoint(x: 0.79512 * width, y: 0.36629 * height))
            path.addLine(to: CGPoint(x: 0.77083 * width, y: 0.29167 * height))
            path.addCurve(to: CGPoint(x: 0.70833 * width, y: 0.22917 * height), control1: CGPoint(x: 0.77083 * width, y: 0.25704 * height), control2: CGPoint(x: 0.74296 * width, y: 0.22917 * height))
            path.addLine(to: CGPoint(x: 0.29167 * width, y: 0.22917 * height))
            return path
        }
    }
}

/// The icon for a draft (pencil and page), drawn as two stacked layers: a solid shape and a second shape at 20% opacity.
struct DraftIcon: View {
    /// Whether to draw the icon in the accent color instead of black.
    var tinted: Bool = false
    var body: some View {
        ZStack {
            ZStack {
                ZStack {
                    Layer0().fill(tinted ? .accent : .black).stroke(tinted ? .accent : .clear)
                }
                .compositingGroup()
                .opacity(0.2)
                ZStack {
                    Layer1().fill(tinted ? .accent : .black).stroke(tinted ? .accent : .clear)
                }
            }
        }
    }

    private struct Layer0: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width = rect.size.width
            let height = rect.size.height
            path.move(to: CGPoint(x: 0.5625 * width, y: 0.0625 * height))
            path.addLine(to: CGPoint(x: 0.5625 * width, y: 0.29167 * height))
            path.addCurve(to: CGPoint(x: 0.625 * width, y: 0.35417 * height), control1: CGPoint(x: 0.5625 * width, y: 0.32629 * height), control2: CGPoint(x: 0.59037 * width, y: 0.35417 * height))
            path.addLine(to: CGPoint(x: 0.85417 * width, y: 0.35417 * height))
            path.addLine(to: CGPoint(x: 0.85417 * width, y: 0.83333 * height))
            path.addCurve(to: CGPoint(x: 0.75 * width, y: 0.9375 * height), control1: CGPoint(x: 0.85417 * width, y: 0.89104 * height), control2: CGPoint(x: 0.80771 * width, y: 0.9375 * height))
            path.addLine(to: CGPoint(x: 0.25 * width, y: 0.9375 * height))
            path.addCurve(to: CGPoint(x: 0.14583 * width, y: 0.83333 * height), control1: CGPoint(x: 0.19229 * width, y: 0.9375 * height), control2: CGPoint(x: 0.14583 * width, y: 0.89104 * height))
            path.addLine(to: CGPoint(x: 0.14583 * width, y: 0.16667 * height))
            path.addCurve(to: CGPoint(x: 0.17628 * width, y: 0.09295 * height), control1: CGPoint(x: 0.14578 * width, y: 0.13902 * height), control2: CGPoint(x: 0.15673 * width, y: 0.1125 * height))
            path.addCurve(to: CGPoint(x: 0.25 * width, y: 0.0625 * height), control1: CGPoint(x: 0.19583 * width, y: 0.0734 * height), control2: CGPoint(x: 0.22236 * width, y: 0.06244 * height))
            path.closeSubpath()
            return path
        }
    }

    private struct Layer1: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width = rect.size.width
            let height = rect.size.height
            path.move(to: CGPoint(x: 0.5625 * width, y: 0.04167 * height))
            path.addCurve(to: CGPoint(x: 0.57725 * width, y: 0.04775 * height), control1: CGPoint(x: 0.56803 * width, y: 0.04166 * height), control2: CGPoint(x: 0.57334 * width, y: 0.04385 * height))
            path.addLine(to: CGPoint(x: 0.86892 * width, y: 0.33942 * height))
            path.addCurve(to: CGPoint(x: 0.87483 * width, y: 0.35417 * height), control1: CGPoint(x: 0.87276 * width, y: 0.34336 * height), control2: CGPoint(x: 0.87489 * width, y: 0.34866 * height))
            path.addLine(to: CGPoint(x: 0.875 * width, y: 0.35417 * height))
            path.addLine(to: CGPoint(x: 0.875 * width, y: 0.83333 * height))
            path.addCurve(to: CGPoint(x: 0.75 * width, y: 0.95833 * height), control1: CGPoint(x: 0.875 * width, y: 0.90221 * height), control2: CGPoint(x: 0.81887 * width, y: 0.95833 * height))
            path.addLine(to: CGPoint(x: 0.25 * width, y: 0.95833 * height))
            path.addCurve(to: CGPoint(x: 0.125 * width, y: 0.83333 * height), control1: CGPoint(x: 0.18112 * width, y: 0.95833 * height), control2: CGPoint(x: 0.125 * width, y: 0.90221 * height))
            path.addLine(to: CGPoint(x: 0.125 * width, y: 0.16667 * height))
            path.addCurve(to: CGPoint(x: 0.25 * width, y: 0.04167 * height), control1: CGPoint(x: 0.125 * width, y: 0.09779 * height), control2: CGPoint(x: 0.18113 * width, y: 0.04167 * height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.25 * width, y: 0.08333 * height))
            path.addCurve(to: CGPoint(x: 0.16667 * width, y: 0.16667 * height), control1: CGPoint(x: 0.20346 * width, y: 0.08333 * height), control2: CGPoint(x: 0.16667 * width, y: 0.12012 * height))
            path.addLine(to: CGPoint(x: 0.16667 * width, y: 0.83333 * height))
            path.addCurve(to: CGPoint(x: 0.25 * width, y: 0.91667 * height), control1: CGPoint(x: 0.16667 * width, y: 0.87988 * height), control2: CGPoint(x: 0.20346 * width, y: 0.91667 * height))
            path.addLine(to: CGPoint(x: 0.75 * width, y: 0.91667 * height))
            path.addCurve(to: CGPoint(x: 0.83333 * width, y: 0.83333 * height), control1: CGPoint(x: 0.79654 * width, y: 0.91667 * height), control2: CGPoint(x: 0.83333 * width, y: 0.87988 * height))
            path.addLine(to: CGPoint(x: 0.83333 * width, y: 0.375 * height))
            path.addLine(to: CGPoint(x: 0.625 * width, y: 0.375 * height))
            path.addCurve(to: CGPoint(x: 0.54167 * width, y: 0.29167 * height), control1: CGPoint(x: 0.57917 * width, y: 0.375 * height), control2: CGPoint(x: 0.54167 * width, y: 0.3375 * height))
            path.addLine(to: CGPoint(x: 0.54167 * width, y: 0.08333 * height))
            path.addLine(to: CGPoint(x: 0.25 * width, y: 0.08333 * height))
            path.move(to: CGPoint(x: 0.58333 * width, y: 0.29167 * height))
            path.addCurve(to: CGPoint(x: 0.625 * width, y: 0.33333 * height), control1: CGPoint(x: 0.58333 * width, y: 0.31512 * height), control2: CGPoint(x: 0.60154 * width, y: 0.33333 * height))
            path.addLine(to: CGPoint(x: 0.80388 * width, y: 0.33333 * height))
            path.addLine(to: CGPoint(x: 0.58333 * width, y: 0.11279 * height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.5 * width, y: 0.20833 * height))
            path.addLine(to: CGPoint(x: 0.5 * width, y: 0.25 * height))
            path.addLine(to: CGPoint(x: 0.3125 * width, y: 0.25 * height))
            path.addCurve(to: CGPoint(x: 0.29167 * width, y: 0.22917 * height), control1: CGPoint(x: 0.30099 * width, y: 0.25 * height), control2: CGPoint(x: 0.29167 * width, y: 0.24067 * height))
            path.addCurve(to: CGPoint(x: 0.3125 * width, y: 0.20833 * height), control1: CGPoint(x: 0.29167 * width, y: 0.21766 * height), control2: CGPoint(x: 0.30099 * width, y: 0.20833 * height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.5 * width, y: 0.33333 * height))
            path.addLine(to: CGPoint(x: 0.5 * width, y: 0.375 * height))
            path.addLine(to: CGPoint(x: 0.3125 * width, y: 0.375 * height))
            path.addCurve(to: CGPoint(x: 0.29167 * width, y: 0.35417 * height), control1: CGPoint(x: 0.30099 * width, y: 0.375 * height), control2: CGPoint(x: 0.29167 * width, y: 0.36567 * height))
            path.addCurve(to: CGPoint(x: 0.3125 * width, y: 0.33333 * height), control1: CGPoint(x: 0.29167 * width, y: 0.34266 * height), control2: CGPoint(x: 0.30099 * width, y: 0.33333 * height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.6875 * width, y: 0.45833 * height))
            path.addCurve(to: CGPoint(x: 0.70833 * width, y: 0.47917 * height), control1: CGPoint(x: 0.69901 * width, y: 0.45833 * height), control2: CGPoint(x: 0.70833 * width, y: 0.46766 * height))
            path.addCurve(to: CGPoint(x: 0.6875 * width, y: 0.5 * height), control1: CGPoint(x: 0.70833 * width, y: 0.49067 * height), control2: CGPoint(x: 0.69901 * width, y: 0.5 * height))
            path.addLine(to: CGPoint(x: 0.3125 * width, y: 0.5 * height))
            path.addCurve(to: CGPoint(x: 0.29167 * width, y: 0.47917 * height), control1: CGPoint(x: 0.30099 * width, y: 0.5 * height), control2: CGPoint(x: 0.29167 * width, y: 0.49067 * height))
            path.addCurve(to: CGPoint(x: 0.3125 * width, y: 0.45833 * height), control1: CGPoint(x: 0.29167 * width, y: 0.46766 * height), control2: CGPoint(x: 0.30099 * width, y: 0.45833 * height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.5625 * width, y: 0.58333 * height))
            path.addCurve(to: CGPoint(x: 0.58333 * width, y: 0.60417 * height), control1: CGPoint(x: 0.57401 * width, y: 0.58333 * height), control2: CGPoint(x: 0.58333 * width, y: 0.59266 * height))
            path.addCurve(to: CGPoint(x: 0.5625 * width, y: 0.625 * height), control1: CGPoint(x: 0.58333 * width, y: 0.61567 * height), control2: CGPoint(x: 0.57401 * width, y: 0.625 * height))
            path.addLine(to: CGPoint(x: 0.3125 * width, y: 0.625 * height))
            path.addCurve(to: CGPoint(x: 0.29167 * width, y: 0.60417 * height), control1: CGPoint(x: 0.30099 * width, y: 0.625 * height), control2: CGPoint(x: 0.29167 * width, y: 0.61567 * height))
            path.addCurve(to: CGPoint(x: 0.3125 * width, y: 0.58333 * height), control1: CGPoint(x: 0.29167 * width, y: 0.59266 * height), control2: CGPoint(x: 0.30099 * width, y: 0.58333 * height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.6875 * width, y: 0.75 * height))
            path.addCurve(to: CGPoint(x: 0.70833 * width, y: 0.76596 * height), control1: CGPoint(x: 0.69904 * width, y: 0.75 * height), control2: CGPoint(x: 0.70833 * width, y: 0.75712 * height))
            path.addLine(to: CGPoint(x: 0.70833 * width, y: 0.77571 * height))
            path.addCurve(to: CGPoint(x: 0.6875 * width, y: 0.79167 * height), control1: CGPoint(x: 0.70833 * width, y: 0.78458 * height), control2: CGPoint(x: 0.69904 * width, y: 0.79167 * height))
            path.addLine(to: CGPoint(x: 0.4375 * width, y: 0.79167 * height))
            path.addCurve(to: CGPoint(x: 0.41667 * width, y: 0.77571 * height), control1: CGPoint(x: 0.42596 * width, y: 0.79167 * height), control2: CGPoint(x: 0.41667 * width, y: 0.78454 * height))
            path.addLine(to: CGPoint(x: 0.41667 * width, y: 0.76596 * height))
            path.addCurve(to: CGPoint(x: 0.4375 * width, y: 0.75 * height), control1: CGPoint(x: 0.41667 * width, y: 0.75708 * height), control2: CGPoint(x: 0.42596 * width, y: 0.75 * height))
            path.closeSubpath()
            return path
        }
    }
}

/// The icon for a sent message, drawn as two stacked layers: a solid shape and a second shape at 20% opacity.
struct SentIcon: View {
    /// Whether to draw the icon in the accent color instead of black.
    var tinted: Bool = false
    var body: some View {
        ZStack {
            ZStack {
                ZStack {
                    Layer0().fill(tinted ? .accent : .black).stroke(tinted ? .accent : .clear)
                }
                .compositingGroup()
                .opacity(0.2)
                ZStack {
                    Layer1().fill(tinted ? .accent : .black).stroke(tinted ? .accent : .clear)
                }
            }
        }
    }

    private struct Layer0: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width = rect.size.width
            let height = rect.size.height
            path.move(to: CGPoint(x: 0.42062 * width, y: 0.57917 * height))
            path.addLine(to: CGPoint(x: 0.15492 * width, y: 0.47825 * height))
            path.addCurve(to: CGPoint(x: 0.10429 * width, y: 0.42117 * height), control1: CGPoint(x: 0.12658 * width, y: 0.47437 * height), control2: CGPoint(x: 0.10429 * width, y: 0.45029 * height))
            path.addCurve(to: CGPoint(x: 0.15708 * width, y: 0.35867 * height), control1: CGPoint(x: 0.10429 * width, y: 0.392 * height), control2: CGPoint(x: 0.12758 * width, y: 0.36658 * height))
            path.addLine(to: CGPoint(x: 0.758 * width, y: 0.12683 * height))
            path.addCurve(to: CGPoint(x: 0.84287 * width, y: 0.10417 * height), control1: CGPoint(x: 0.79183 * width, y: 0.11317 * height), control2: CGPoint(x: 0.81371 * width, y: 0.10417 * height))
            path.addCurve(to: CGPoint(x: 0.89567 * width, y: 0.15696 * height), control1: CGPoint(x: 0.87204 * width, y: 0.10417 * height), control2: CGPoint(x: 0.89567 * width, y: 0.12783 * height))
            path.addCurve(to: CGPoint(x: 0.87404 * width, y: 0.23138 * height), control1: CGPoint(x: 0.89567 * width, y: 0.18608 * height), control2: CGPoint(x: 0.88321 * width, y: 0.20313 * height))
            path.addLine(to: CGPoint(x: 0.64117 * width, y: 0.84596 * height))
            path.addCurve(to: CGPoint(x: 0.579 * width, y: 0.89583 * height), control1: CGPoint(x: 0.62892 * width, y: 0.87304 * height), control2: CGPoint(x: 0.60817 * width, y: 0.89583 * height))
            path.addCurve(to: CGPoint(x: 0.52042 * width, y: 0.84458 * height), control1: CGPoint(x: 0.54954 * width, y: 0.89545 * height), control2: CGPoint(x: 0.52471 * width, y: 0.87373 * height))
            path.closeSubpath()
            return path
        }
    }

    private struct Layer1: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width = rect.size.width
            let height = rect.size.height
            path.move(to: CGPoint(x: 0.84288 * width, y: 0.08333 * height))
            path.addCurve(to: CGPoint(x: 0.9165 * width, y: 0.157 * height), control1: CGPoint(x: 0.88325 * width, y: 0.08333 * height), control2: CGPoint(x: 0.9165 * width, y: 0.11658 * height))
            path.addCurve(to: CGPoint(x: 0.89379 * width, y: 0.23787 * height), control1: CGPoint(x: 0.9165 * width, y: 0.19204 * height), control2: CGPoint(x: 0.90204 * width, y: 0.2125 * height))
            path.addLine(to: CGPoint(x: 0.89346 * width, y: 0.23879 * height))
            path.addLine(to: CGPoint(x: 0.66063 * width, y: 0.85337 * height))
            path.addLine(to: CGPoint(x: 0.66008 * width, y: 0.8545 * height))
            path.addCurve(to: CGPoint(x: 0.57904 * width, y: 0.91667 * height), control1: CGPoint(x: 0.646 * width, y: 0.88567 * height), control2: CGPoint(x: 0.61904 * width, y: 0.91667 * height))
            path.addCurve(to: CGPoint(x: 0.52663 * width, y: 0.89471 * height), control1: CGPoint(x: 0.55817 * width, y: 0.91667 * height), control2: CGPoint(x: 0.53996 * width, y: 0.90729 * height))
            path.addCurve(to: CGPoint(x: 0.50062 * width, y: 0.85125 * height), control1: CGPoint(x: 0.51379 * width, y: 0.88258 * height), control2: CGPoint(x: 0.50483 * width, y: 0.8675 * height))
            path.addLine(to: CGPoint(x: 0.50104 * width, y: 0.85221 * height))
            path.addLine(to: CGPoint(x: 0.50017 * width, y: 0.84937 * height))
            path.addLine(to: CGPoint(x: 0.50062 * width, y: 0.85125 * height))
            path.addLine(to: CGPoint(x: 0.40062 * width, y: 0.59938 * height))
            path.addLine(to: CGPoint(x: 0.14846 * width, y: 0.49821 * height))
            path.addLine(to: CGPoint(x: 0.15112 * width, y: 0.49879 * height))
            path.addLine(to: CGPoint(x: 0.14712 * width, y: 0.49762 * height))
            path.addLine(to: CGPoint(x: 0.14846 * width, y: 0.49821 * height))
            path.addCurve(to: CGPoint(x: 0.0835 * width, y: 0.42112 * height), control1: CGPoint(x: 0.115 * width, y: 0.49071 * height), control2: CGPoint(x: 0.0835 * width, y: 0.46162 * height))
            path.addCurve(to: CGPoint(x: 0.1505 * width, y: 0.33896 * height), control1: CGPoint(x: 0.0835 * width, y: 0.38133 * height), control2: CGPoint(x: 0.11342 * width, y: 0.34937 * height))
            path.addLine(to: CGPoint(x: 0.7505 * width, y: 0.10733 * height))
            path.addCurve(to: CGPoint(x: 0.84287 * width, y: 0.08333 * height), control1: CGPoint(x: 0.78412 * width, y: 0.09379 * height), control2: CGPoint(x: 0.80954 * width, y: 0.08333 * height))
            path.move(to: CGPoint(x: 0.84287 * width, y: 0.125 * height))
            path.addCurve(to: CGPoint(x: 0.76583 * width, y: 0.14617 * height), control1: CGPoint(x: 0.818 * width, y: 0.125 * height), control2: CGPoint(x: 0.79971 * width, y: 0.1325 * height))
            path.addLine(to: CGPoint(x: 0.7655 * width, y: 0.14625 * height))
            path.addLine(to: CGPoint(x: 0.16467 * width, y: 0.37817 * height))
            path.addLine(to: CGPoint(x: 0.16246 * width, y: 0.37875 * height))
            path.addCurve(to: CGPoint(x: 0.12513 * width, y: 0.42117 * height), control1: CGPoint(x: 0.14113 * width, y: 0.3845 * height), control2: CGPoint(x: 0.12513 * width, y: 0.40308 * height))
            path.addCurve(to: CGPoint(x: 0.15888 * width, y: 0.45783 * height), control1: CGPoint(x: 0.12513 * width, y: 0.43783 * height), control2: CGPoint(x: 0.14421 * width, y: 0.45508 * height))
            path.addCurve(to: CGPoint(x: 0.16263 * width, y: 0.459 * height), control1: CGPoint(x: 0.16016 * width, y: 0.4581 * height), control2: CGPoint(x: 0.16141 * width, y: 0.45849 * height))
            path.addLine(to: CGPoint(x: 0.41167 * width, y: 0.55892 * height))
            path.addLine(to: CGPoint(x: 0.58933 * width, y: 0.38108 * height))
            path.addCurve(to: CGPoint(x: 0.60945 * width, y: 0.37562 * height), control1: CGPoint(x: 0.59458 * width, y: 0.3758 * height), control2: CGPoint(x: 0.60225 * width, y: 0.37372 * height))
            path.addCurve(to: CGPoint(x: 0.62424 * width, y: 0.3903 * height), control1: CGPoint(x: 0.61665 * width, y: 0.37752 * height), control2: CGPoint(x: 0.62229 * width, y: 0.38312 * height))
            path.addCurve(to: CGPoint(x: 0.61892 * width, y: 0.41046 * height), control1: CGPoint(x: 0.62619 * width, y: 0.39749 * height), control2: CGPoint(x: 0.62416 * width, y: 0.40517 * height))
            path.addLine(to: CGPoint(x: 0.44108 * width, y: 0.58837 * height))
            path.addLine(to: CGPoint(x: 0.53971 * width, y: 0.83683 * height))
            path.addCurve(to: CGPoint(x: 0.54063 * width, y: 0.83983 * height), control1: CGPoint(x: 0.54005 * width, y: 0.83782 * height), control2: CGPoint(x: 0.54036 * width, y: 0.83882 * height))
            path.addCurve(to: CGPoint(x: 0.55529 * width, y: 0.86442 * height), control1: CGPoint(x: 0.54322 * width, y: 0.84919 * height), control2: CGPoint(x: 0.54829 * width, y: 0.85769 * height))
            path.addCurve(to: CGPoint(x: 0.57904 * width, y: 0.875 * height), control1: CGPoint(x: 0.5625 * width, y: 0.87125 * height), control2: CGPoint(x: 0.57071 * width, y: 0.875 * height))
            path.addCurve(to: CGPoint(x: 0.62208 * width, y: 0.8375 * height), control1: CGPoint(x: 0.59725 * width, y: 0.875 * height), control2: CGPoint(x: 0.61167 * width, y: 0.86042 * height))
            path.addLine(to: CGPoint(x: 0.85425 * width, y: 0.225 * height))
            path.addCurve(to: CGPoint(x: 0.87483 * width, y: 0.157 * height), control1: CGPoint(x: 0.86442 * width, y: 0.19383 * height), control2: CGPoint(x: 0.87483 * width, y: 0.18021 * height))
            path.addCurve(to: CGPoint(x: 0.86557 * width, y: 0.13429 * height), control1: CGPoint(x: 0.87492 * width, y: 0.14849 * height), control2: CGPoint(x: 0.87159 * width, y: 0.14031 * height))
            path.addCurve(to: CGPoint(x: 0.84288 * width, y: 0.125 * height), control1: CGPoint(x: 0.85956 * width, y: 0.12827 * height), control2: CGPoint(x: 0.85138 * width, y: 0.12492 * height))
            return path
        }
    }
}

/// The icon for an archive box, drawn as two stacked layers: a solid shape and a second shape at 20% opacity.
struct ArchiveIcon: View {
    /// Whether to draw the icon in the accent color instead of black.
    var tinted: Bool = false
    var body: some View {
        ZStack {
            ZStack {
                ZStack {
                    Layer0().fill(tinted ? .accent : .black).stroke(tinted ? .accent : .clear)
                }
                .compositingGroup()
                .opacity(0.2)
                ZStack {
                    Layer1().fill(tinted ? .accent : .black).stroke(tinted ? .accent : .clear)
                }
            }
        }
    }

    private struct Layer0: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width = rect.size.width
            let height = rect.size.height
            path.move(to: CGPoint(x: 0.75 * width, y: 0.10417 * height))
            path.addCurve(to: CGPoint(x: 0.89583 * width, y: 0.25 * height), control1: CGPoint(x: 0.83079 * width, y: 0.10417 * height), control2: CGPoint(x: 0.89583 * width, y: 0.16921 * height))
            path.addLine(to: CGPoint(x: 0.89583 * width, y: 0.75 * height))
            path.addCurve(to: CGPoint(x: 0.75 * width, y: 0.89583 * height), control1: CGPoint(x: 0.89583 * width, y: 0.83079 * height), control2: CGPoint(x: 0.83079 * width, y: 0.89583 * height))
            path.addLine(to: CGPoint(x: 0.25 * width, y: 0.89583 * height))
            path.addCurve(to: CGPoint(x: 0.10417 * width, y: 0.75 * height), control1: CGPoint(x: 0.16921 * width, y: 0.89583 * height), control2: CGPoint(x: 0.10417 * width, y: 0.83079 * height))
            path.addLine(to: CGPoint(x: 0.10417 * width, y: 0.25 * height))
            path.addCurve(to: CGPoint(x: 0.14676 * width, y: 0.14676 * height), control1: CGPoint(x: 0.10406 * width, y: 0.21129 * height), control2: CGPoint(x: 0.11938 * width, y: 0.17413 * height))
            path.addCurve(to: CGPoint(x: 0.25 * width, y: 0.10417 * height), control1: CGPoint(x: 0.17413 * width, y: 0.11938 * height), control2: CGPoint(x: 0.21129 * width, y: 0.10406 * height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.77083 * width, y: 0.19108 * height))
            path.addCurve(to: CGPoint(x: 0.22917 * width, y: 0.19108 * height), control1: CGPoint(x: 0.60417 * width, y: 0.1875 * height), control2: CGPoint(x: 0.39583 * width, y: 0.19108 * height))
            path.addCurve(to: CGPoint(x: 0.1875 * width, y: 0.25 * height), control1: CGPoint(x: 0.20488 * width, y: 0.19963 * height), control2: CGPoint(x: 0.1875 * width, y: 0.22271 * height))
            path.addLine(to: CGPoint(x: 0.1875 * width, y: 0.35417 * height))
            path.addLine(to: CGPoint(x: 0.35417 * width, y: 0.35417 * height))
            path.addLine(to: CGPoint(x: 0.35417 * width, y: 0.375 * height))
            path.addCurve(to: CGPoint(x: 0.39676 * width, y: 0.47824 * height), control1: CGPoint(x: 0.35406 * width, y: 0.41371 * height), control2: CGPoint(x: 0.36938 * width, y: 0.45087 * height))
            path.addCurve(to: CGPoint(x: 0.5 * width, y: 0.52083 * height), control1: CGPoint(x: 0.42413 * width, y: 0.50562 * height), control2: CGPoint(x: 0.46129 * width, y: 0.52094 * height))
            path.addCurve(to: CGPoint(x: 0.64583 * width, y: 0.375 * height), control1: CGPoint(x: 0.58079 * width, y: 0.52083 * height), control2: CGPoint(x: 0.64583 * width, y: 0.45579 * height))
            path.addLine(to: CGPoint(x: 0.64583 * width, y: 0.35417 * height))
            path.addLine(to: CGPoint(x: 0.8125 * width, y: 0.35417 * height))
            path.addLine(to: CGPoint(x: 0.8125 * width, y: 0.25 * height))
            path.addCurve(to: CGPoint(x: 0.77083 * width, y: 0.19108 * height), control1: CGPoint(x: 0.8125 * width, y: 0.22271 * height), control2: CGPoint(x: 0.79512 * width, y: 0.19963 * height))
            return path
        }
    }

    private struct Layer1: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width = rect.size.width
            let height = rect.size.height
            path.move(to: CGPoint(x: 0.75 * width, y: 0.08333 * height))
            path.addCurve(to: CGPoint(x: 0.91667 * width, y: 0.25 * height), control1: CGPoint(x: 0.84196 * width, y: 0.08333 * height), control2: CGPoint(x: 0.91667 * width, y: 0.15804 * height))
            path.addLine(to: CGPoint(x: 0.91667 * width, y: 0.75 * height))
            path.addCurve(to: CGPoint(x: 0.75 * width, y: 0.91667 * height), control1: CGPoint(x: 0.91667 * width, y: 0.84196 * height), control2: CGPoint(x: 0.84196 * width, y: 0.91667 * height))
            path.addLine(to: CGPoint(x: 0.25 * width, y: 0.91667 * height))
            path.addCurve(to: CGPoint(x: 0.08333 * width, y: 0.75 * height), control1: CGPoint(x: 0.15804 * width, y: 0.91667 * height), control2: CGPoint(x: 0.08333 * width, y: 0.84196 * height))
            path.addLine(to: CGPoint(x: 0.08333 * width, y: 0.25 * height))
            path.addCurve(to: CGPoint(x: 0.25 * width, y: 0.08333 * height), control1: CGPoint(x: 0.08333 * width, y: 0.15804 * height), control2: CGPoint(x: 0.15804 * width, y: 0.08333 * height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.25 * width, y: 0.125 * height))
            path.addQuadCurve(to: CGPoint(x: 0.22462 * width, y: 0.1275 * height), control: CGPoint(x: 0.23692 * width, y: 0.125 * height))
            path.addCurve(to: CGPoint(x: 0.12754 * width, y: 0.22458 * height), control1: CGPoint(x: 0.17563 * width, y: 0.1373 * height), control2: CGPoint(x: 0.13734 * width, y: 0.17559 * height))
            path.addLine(to: CGPoint(x: 0.12754 * width, y: 0.22479 * height))
            path.addQuadCurve(to: CGPoint(x: 0.12567 * width, y: 0.23713 * height), control: CGPoint(x: 0.12629 * width, y: 0.23083 * height))
            path.addLine(to: CGPoint(x: 0.12567 * width, y: 0.23721 * height))
            path.addCurve(to: CGPoint(x: 0.125 * width, y: 0.25 * height), control1: CGPoint(x: 0.12523 * width, y: 0.24146 * height), control2: CGPoint(x: 0.125 * width, y: 0.24573 * height))
            path.addLine(to: CGPoint(x: 0.125 * width, y: 0.33333 * height))
            path.addLine(to: CGPoint(x: 0.16667 * width, y: 0.33333 * height))
            path.addLine(to: CGPoint(x: 0.16667 * width, y: 0.25 * height))
            path.addCurve(to: CGPoint(x: 0.20833 * width, y: 0.17796 * height), control1: CGPoint(x: 0.16667 * width, y: 0.21933 * height), control2: CGPoint(x: 0.1835 * width, y: 0.1925 * height))
            path.addCurve(to: CGPoint(x: 0.25 * width, y: 0.16667 * height), control1: CGPoint(x: 0.21183 * width, y: 0.17679 * height), control2: CGPoint(x: 0.22917 * width, y: 0.16667 * height))
            path.addLine(to: CGPoint(x: 0.75 * width, y: 0.16667 * height))
            path.addCurve(to: CGPoint(x: 0.79167 * width, y: 0.17796 * height), control1: CGPoint(x: 0.76762 * width, y: 0.16667 * height), control2: CGPoint(x: 0.77083 * width, y: 0.16667 * height))
            path.addCurve(to: CGPoint(x: 0.83333 * width, y: 0.25 * height), control1: CGPoint(x: 0.8165 * width, y: 0.19246 * height), control2: CGPoint(x: 0.83333 * width, y: 0.21933 * height))
            path.addLine(to: CGPoint(x: 0.83333 * width, y: 0.33333 * height))
            path.addLine(to: CGPoint(x: 0.875 * width, y: 0.33333 * height))
            path.addLine(to: CGPoint(x: 0.875 * width, y: 0.25 * height))
            path.addQuadCurve(to: CGPoint(x: 0.87246 * width, y: 0.22462 * height), control: CGPoint(x: 0.875 * width, y: 0.23692 * height))
            path.addCurve(to: CGPoint(x: 0.77537 * width, y: 0.12754 * height), control1: CGPoint(x: 0.86266 * width, y: 0.17563 * height), control2: CGPoint(x: 0.82437 * width, y: 0.13734 * height))
            path.addLine(to: CGPoint(x: 0.77521 * width, y: 0.12754 * height))
            path.addQuadCurve(to: CGPoint(x: 0.76287 * width, y: 0.12567 * height), control: CGPoint(x: 0.76917 * width, y: 0.12629 * height))
            path.addLine(to: CGPoint(x: 0.76279 * width, y: 0.12567 * height))
            path.addQuadCurve(to: CGPoint(x: 0.75 * width, y: 0.125 * height), control: CGPoint(x: 0.7565 * width, y: 0.125 * height))
            path.addLine(to: CGPoint(x: 0.25 * width, y: 0.125 * height))
            path.move(to: CGPoint(x: 0.25 * width, y: 0.20833 * height))
            path.addCurve(to: CGPoint(x: 0.20833 * width, y: 0.25 * height), control1: CGPoint(x: 0.22654 * width, y: 0.20833 * height), control2: CGPoint(x: 0.20833 * width, y: 0.22654 * height))
            path.addLine(to: CGPoint(x: 0.20833 * width, y: 0.33333 * height))
            path.addLine(to: CGPoint(x: 0.35417 * width, y: 0.33333 * height))
            path.addCurve(to: CGPoint(x: 0.375 * width, y: 0.35417 * height), control1: CGPoint(x: 0.36567 * width, y: 0.33333 * height), control2: CGPoint(x: 0.375 * width, y: 0.34266 * height))
            path.addLine(to: CGPoint(x: 0.375 * width, y: 0.375 * height))
            path.addCurve(to: CGPoint(x: 0.5 * width, y: 0.5 * height), control1: CGPoint(x: 0.375 * width, y: 0.45037 * height), control2: CGPoint(x: 0.43071 * width, y: 0.5 * height))
            path.addCurve(to: CGPoint(x: 0.625 * width, y: 0.375 * height), control1: CGPoint(x: 0.56929 * width, y: 0.5 * height), control2: CGPoint(x: 0.625 * width, y: 0.44429 * height))
            path.addLine(to: CGPoint(x: 0.625 * width, y: 0.35417 * height))
            path.addCurve(to: CGPoint(x: 0.64583 * width, y: 0.33333 * height), control1: CGPoint(x: 0.625 * width, y: 0.34266 * height), control2: CGPoint(x: 0.63433 * width, y: 0.33333 * height))
            path.addLine(to: CGPoint(x: 0.79167 * width, y: 0.33333 * height))
            path.addLine(to: CGPoint(x: 0.79167 * width, y: 0.25 * height))
            path.addCurve(to: CGPoint(x: 0.75 * width, y: 0.20833 * height), control1: CGPoint(x: 0.79167 * width, y: 0.22654 * height), control2: CGPoint(x: 0.77346 * width, y: 0.20833 * height))
            path.addLine(to: CGPoint(x: 0.25 * width, y: 0.20833 * height))
            path.move(to: CGPoint(x: 0.125 * width, y: 0.75 * height))
            path.addCurve(to: CGPoint(x: 0.12562 * width, y: 0.76279 * height), control1: CGPoint(x: 0.12499 * width, y: 0.75427 * height), control2: CGPoint(x: 0.1252 * width, y: 0.75854 * height))
            path.addLine(to: CGPoint(x: 0.12563 * width, y: 0.76288 * height))
            path.addCurve(to: CGPoint(x: 0.1275 * width, y: 0.77521 * height), control1: CGPoint(x: 0.12604 * width, y: 0.76701 * height), control2: CGPoint(x: 0.12667 * width, y: 0.77113 * height))
            path.addLine(to: CGPoint(x: 0.1275 * width, y: 0.77542 * height))
            path.addCurve(to: CGPoint(x: 0.22458 * width, y: 0.8725 * height), control1: CGPoint(x: 0.1373 * width, y: 0.82441 * height), control2: CGPoint(x: 0.17559 * width, y: 0.8627 * height))
            path.addLine(to: CGPoint(x: 0.22479 * width, y: 0.8725 * height))
            path.addCurve(to: CGPoint(x: 0.25 * width, y: 0.875 * height), control1: CGPoint(x: 0.23309 * width, y: 0.87418 * height), control2: CGPoint(x: 0.24153 * width, y: 0.87502 * height))
            path.addLine(to: CGPoint(x: 0.5 * width, y: 0.875 * height))
            path.addLine(to: CGPoint(x: 0.5 * width, y: 0.83333 * height))
            path.addLine(to: CGPoint(x: 0.54167 * width, y: 0.83333 * height))
            path.addLine(to: CGPoint(x: 0.54167 * width, y: 0.875 * height))
            path.addLine(to: CGPoint(x: 0.75 * width, y: 0.875 * height))
            path.addQuadCurve(to: CGPoint(x: 0.77542 * width, y: 0.8725 * height), control: CGPoint(x: 0.76312 * width, y: 0.875 * height))
            path.addCurve(to: CGPoint(x: 0.8725 * width, y: 0.77542 * height), control1: CGPoint(x: 0.82441 * width, y: 0.8627 * height), control2: CGPoint(x: 0.8627 * width, y: 0.82441 * height))
            path.addQuadCurve(to: CGPoint(x: 0.875 * width, y: 0.75 * height), control: CGPoint(x: 0.875 * width, y: 0.76313 * height))
            path.addLine(to: CGPoint(x: 0.875 * width, y: 0.375 * height))
            path.addLine(to: CGPoint(x: 0.66667 * width, y: 0.375 * height))
            path.addCurve(to: CGPoint(x: 0.5 * width, y: 0.54167 * height), control1: CGPoint(x: 0.66667 * width, y: 0.46679 * height), control2: CGPoint(x: 0.59179 * width, y: 0.54167 * height))
            path.addCurve(to: CGPoint(x: 0.33333 * width, y: 0.375 * height), control1: CGPoint(x: 0.40821 * width, y: 0.54167 * height), control2: CGPoint(x: 0.33333 * width, y: 0.47917 * height))
            path.addLine(to: CGPoint(x: 0.125 * width, y: 0.375 * height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.45833 * width, y: 0.83333 * height))
            path.addLine(to: CGPoint(x: 0.45833 * width, y: 0.79167 * height))
            path.addLine(to: CGPoint(x: 0.5 * width, y: 0.79167 * height))
            path.addLine(to: CGPoint(x: 0.5 * width, y: 0.83333 * height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.5 * width, y: 0.75 * height))
            path.addLine(to: CGPoint(x: 0.54167 * width, y: 0.75 * height))
            path.addLine(to: CGPoint(x: 0.54167 * width, y: 0.79167 * height))
            path.addLine(to: CGPoint(x: 0.5 * width, y: 0.79167 * height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.45833 * width, y: 0.75 * height))
            path.addLine(to: CGPoint(x: 0.45833 * width, y: 0.70833 * height))
            path.addLine(to: CGPoint(x: 0.5 * width, y: 0.70833 * height))
            path.addLine(to: CGPoint(x: 0.5 * width, y: 0.75 * height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.5 * width, y: 0.66667 * height))
            path.addLine(to: CGPoint(x: 0.54167 * width, y: 0.66667 * height))
            path.addLine(to: CGPoint(x: 0.54167 * width, y: 0.70833 * height))
            path.addLine(to: CGPoint(x: 0.5 * width, y: 0.70833 * height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.45833 * width, y: 0.66667 * height))
            path.addLine(to: CGPoint(x: 0.45833 * width, y: 0.625 * height))
            path.addLine(to: CGPoint(x: 0.5 * width, y: 0.625 * height))
            path.addLine(to: CGPoint(x: 0.5 * width, y: 0.66667 * height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.5 * width, y: 0.58333 * height))
            path.addLine(to: CGPoint(x: 0.54167 * width, y: 0.58333 * height))
            path.addLine(to: CGPoint(x: 0.54167 * width, y: 0.625 * height))
            path.addLine(to: CGPoint(x: 0.5 * width, y: 0.625 * height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.45833 * width, y: 0.58333 * height))
            path.addLine(to: CGPoint(x: 0.45833 * width, y: 0.54167 * height))
            path.addLine(to: CGPoint(x: 0.5 * width, y: 0.54167 * height))
            path.addLine(to: CGPoint(x: 0.5 * width, y: 0.58333 * height))
            path.closeSubpath()
            return path
        }
    }
}

/// The icon for a trash can, drawn as two stacked layers: a solid shape and a second shape at 20% opacity.
struct TrashIcon: View {
    /// Whether to draw the icon in the accent color instead of black.
    var tinted: Bool = false
    var body: some View {
        ZStack {
            ZStack {
                ZStack {
                    Layer0().fill(tinted ? .accent : .black).stroke(tinted ? .accent : .clear)
                }
                .compositingGroup()
                .opacity(0.2)
                ZStack {
                    Layer1().fill(tinted ? .accent : .black).stroke(tinted ? .accent : .clear)
                }
            }
        }
    }

    private struct Layer0: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width = rect.size.width
            let height = rect.size.height
            path.move(to: CGPoint(x: 0.60417 * width, y: 0.0625 * height))
            path.addCurve(to: CGPoint(x: 0.64583 * width, y: 0.10417 * height), control1: CGPoint(x: 0.62725 * width, y: 0.0625 * height), control2: CGPoint(x: 0.64583 * width, y: 0.08108 * height))
            path.addLine(to: CGPoint(x: 0.75 * width, y: 0.10417 * height))
            path.addCurve(to: CGPoint(x: 0.85417 * width, y: 0.19792 * height), control1: CGPoint(x: 0.80771 * width, y: 0.10417 * height), control2: CGPoint(x: 0.85417 * width, y: 0.14596 * height))
            path.addQuadCurve(to: CGPoint(x: 0.85342 * width, y: 0.20833 * height), control: CGPoint(x: 0.85412 * width, y: 0.20321 * height))
            path.addLine(to: CGPoint(x: 0.85417 * width, y: 0.20833 * height))
            path.addLine(to: CGPoint(x: 0.85417 * width, y: 0.3125 * height))
            path.addLine(to: CGPoint(x: 0.8125 * width, y: 0.3125 * height))
            path.addLine(to: CGPoint(x: 0.8125 * width, y: 0.83333 * height))
            path.addCurve(to: CGPoint(x: 0.70833 * width, y: 0.9375 * height), control1: CGPoint(x: 0.8125 * width, y: 0.89104 * height), control2: CGPoint(x: 0.76604 * width, y: 0.9375 * height))
            path.addLine(to: CGPoint(x: 0.29167 * width, y: 0.9375 * height))
            path.addCurve(to: CGPoint(x: 0.1875 * width, y: 0.83333 * height), control1: CGPoint(x: 0.23396 * width, y: 0.9375 * height), control2: CGPoint(x: 0.1875 * width, y: 0.89104 * height))
            path.addLine(to: CGPoint(x: 0.1875 * width, y: 0.3125 * height))
            path.addLine(to: CGPoint(x: 0.14583 * width, y: 0.3125 * height))
            path.addLine(to: CGPoint(x: 0.14583 * width, y: 0.20833 * height))
            path.addLine(to: CGPoint(x: 0.14658 * width, y: 0.20833 * height))
            path.addQuadCurve(to: CGPoint(x: 0.14583 * width, y: 0.19792 * height), control: CGPoint(x: 0.14592 * width, y: 0.20321 * height))
            path.addCurve(to: CGPoint(x: 0.25 * width, y: 0.10417 * height), control1: CGPoint(x: 0.14583 * width, y: 0.14596 * height), control2: CGPoint(x: 0.19229 * width, y: 0.10417 * height))
            path.addLine(to: CGPoint(x: 0.35417 * width, y: 0.10417 * height))
            path.addCurve(to: CGPoint(x: 0.39583 * width, y: 0.0625 * height), control1: CGPoint(x: 0.35417 * width, y: 0.08108 * height), control2: CGPoint(x: 0.37275 * width, y: 0.0625 * height))
            path.closeSubpath()
            return path
        }
    }

    private struct Layer1: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width = rect.size.width
            let height = rect.size.height
            path.move(to: CGPoint(x: 0.60417 * width, y: 0.04167 * height))
            path.addCurve(to: CGPoint(x: 0.66292 * width, y: 0.08333 * height), control1: CGPoint(x: 0.63113 * width, y: 0.04167 * height), control2: CGPoint(x: 0.65425 * width, y: 0.05917 * height))
            path.addLine(to: CGPoint(x: 0.75 * width, y: 0.08333 * height))
            path.addCurve(to: CGPoint(x: 0.83876 * width, y: 0.12052 * height), control1: CGPoint(x: 0.78336 * width, y: 0.08341 * height), control2: CGPoint(x: 0.81531 * width, y: 0.0968 * height))
            path.addCurve(to: CGPoint(x: 0.87492 * width, y: 0.20971 * height), control1: CGPoint(x: 0.86221 * width, y: 0.14425 * height), control2: CGPoint(x: 0.87523 * width, y: 0.17635 * height))
            path.addCurve(to: CGPoint(x: 0.875 * width, y: 0.21088 * height), control1: CGPoint(x: 0.87496 * width, y: 0.20942 * height), control2: CGPoint(x: 0.875 * width, y: 0.20838 * height))
            path.addLine(to: CGPoint(x: 0.875 * width, y: 0.28917 * height))
            path.addCurve(to: CGPoint(x: 0.83308 * width, y: 0.33317 * height), control1: CGPoint(x: 0.87474 * width, y: 0.31256 * height), control2: CGPoint(x: 0.85644 * width, y: 0.33177 * height))
            path.addCurve(to: CGPoint(x: 0.83333 * width, y: 0.33583 * height), control1: CGPoint(x: 0.83313 * width, y: 0.33408 * height), control2: CGPoint(x: 0.83333 * width, y: 0.33492 * height))
            path.addLine(to: CGPoint(x: 0.83333 * width, y: 0.83333 * height))
            path.addCurve(to: CGPoint(x: 0.70833 * width, y: 0.95833 * height), control1: CGPoint(x: 0.83333 * width, y: 0.90221 * height), control2: CGPoint(x: 0.77721 * width, y: 0.95833 * height))
            path.addLine(to: CGPoint(x: 0.29167 * width, y: 0.95833 * height))
            path.addCurve(to: CGPoint(x: 0.16667 * width, y: 0.83333 * height), control1: CGPoint(x: 0.22279 * width, y: 0.95833 * height), control2: CGPoint(x: 0.16667 * width, y: 0.90221 * height))
            path.addLine(to: CGPoint(x: 0.16667 * width, y: 0.33587 * height))
            path.addQuadCurve(to: CGPoint(x: 0.16692 * width, y: 0.33317 * height), control: CGPoint(x: 0.16675 * width, y: 0.3345 * height))
            path.addCurve(to: CGPoint(x: 0.125 * width, y: 0.28913 * height), control1: CGPoint(x: 0.14383 * width, y: 0.33196 * height), control2: CGPoint(x: 0.125 * width, y: 0.31246 * height))
            path.addLine(to: CGPoint(x: 0.125 * width, y: 0.21088 * height))
            path.addCurve(to: CGPoint(x: 0.12508 * width, y: 0.20971 * height), control1: CGPoint(x: 0.125 * width, y: 0.20854 * height), control2: CGPoint(x: 0.12508 * width, y: 0.20946 * height))
            path.addCurve(to: CGPoint(x: 0.125 * width, y: 0.20833 * height), control1: CGPoint(x: 0.12504 * width, y: 0.20979 * height), control2: CGPoint(x: 0.125 * width, y: 0.21 * height))
            path.addCurve(to: CGPoint(x: 0.25 * width, y: 0.08333 * height), control1: CGPoint(x: 0.125 * width, y: 0.13946 * height), control2: CGPoint(x: 0.18113 * width, y: 0.08333 * height))
            path.addLine(to: CGPoint(x: 0.33708 * width, y: 0.08333 * height))
            path.addCurve(to: CGPoint(x: 0.39583 * width, y: 0.04167 * height), control1: CGPoint(x: 0.34575 * width, y: 0.05917 * height), control2: CGPoint(x: 0.36888 * width, y: 0.04167 * height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.39583 * width, y: 0.08333 * height))
            path.addCurve(to: CGPoint(x: 0.375 * width, y: 0.10417 * height), control1: CGPoint(x: 0.38392 * width, y: 0.08333 * height), control2: CGPoint(x: 0.375 * width, y: 0.09225 * height))
            path.addCurve(to: CGPoint(x: 0.38098 * width, y: 0.11902 * height), control1: CGPoint(x: 0.37489 * width, y: 0.10973 * height), control2: CGPoint(x: 0.37704 * width, y: 0.11509 * height))
            path.addCurve(to: CGPoint(x: 0.39583 * width, y: 0.125 * height), control1: CGPoint(x: 0.38491 * width, y: 0.12296 * height), control2: CGPoint(x: 0.39027 * width, y: 0.12511 * height))
            path.addLine(to: CGPoint(x: 0.60417 * width, y: 0.125 * height))
            path.addCurve(to: CGPoint(x: 0.625 * width, y: 0.10417 * height), control1: CGPoint(x: 0.61608 * width, y: 0.125 * height), control2: CGPoint(x: 0.625 * width, y: 0.11608 * height))
            path.addCurve(to: CGPoint(x: 0.60417 * width, y: 0.08333 * height), control1: CGPoint(x: 0.625 * width, y: 0.09225 * height), control2: CGPoint(x: 0.61608 * width, y: 0.08333 * height))
            path.addLine(to: CGPoint(x: 0.39583 * width, y: 0.08333 * height))
            path.move(to: CGPoint(x: 0.25 * width, y: 0.125 * height))
            path.addCurve(to: CGPoint(x: 0.16667 * width, y: 0.20833 * height), control1: CGPoint(x: 0.20346 * width, y: 0.125 * height), control2: CGPoint(x: 0.16667 * width, y: 0.16179 * height))
            path.addQuadCurve(to: CGPoint(x: 0.16675 * width, y: 0.20958 * height), control: CGPoint(x: 0.16667 * width, y: 0.20638 * height))
            path.addLine(to: CGPoint(x: 0.16675 * width, y: 0.21079 * height))
            path.addLine(to: CGPoint(x: 0.16667 * width, y: 0.21083 * height))
            path.addLine(to: CGPoint(x: 0.16667 * width, y: 0.28917 * height))
            path.addCurve(to: CGPoint(x: 0.16917 * width, y: 0.29167 * height), control1: CGPoint(x: 0.16667 * width, y: 0.29096 * height), control2: CGPoint(x: 0.16742 * width, y: 0.29167 * height))
            path.addLine(to: CGPoint(x: 0.83083 * width, y: 0.29167 * height))
            path.addCurve(to: CGPoint(x: 0.83333 * width, y: 0.28917 * height), control1: CGPoint(x: 0.83263 * width, y: 0.29167 * height), control2: CGPoint(x: 0.83333 * width, y: 0.29096 * height))
            path.addLine(to: CGPoint(x: 0.83333 * width, y: 0.21083 * height))
            path.addLine(to: CGPoint(x: 0.83325 * width, y: 0.21083 * height))
            path.addCurve(to: CGPoint(x: 0.80997 * width, y: 0.15012 * height), control1: CGPoint(x: 0.8341 * width, y: 0.18827 * height), control2: CGPoint(x: 0.82569 * width, y: 0.16633 * height))
            path.addCurve(to: CGPoint(x: 0.75 * width, y: 0.125 * height), control1: CGPoint(x: 0.79425 * width, y: 0.13391 * height), control2: CGPoint(x: 0.77258 * width, y: 0.12484 * height))
            path.addLine(to: CGPoint(x: 0.66292 * width, y: 0.125 * height))
            path.addCurve(to: CGPoint(x: 0.60417 * width, y: 0.16667 * height), control1: CGPoint(x: 0.65425 * width, y: 0.14917 * height), control2: CGPoint(x: 0.63113 * width, y: 0.16667 * height))
            path.addLine(to: CGPoint(x: 0.39583 * width, y: 0.16667 * height))
            path.addCurve(to: CGPoint(x: 0.33708 * width, y: 0.125 * height), control1: CGPoint(x: 0.36888 * width, y: 0.16667 * height), control2: CGPoint(x: 0.34575 * width, y: 0.14917 * height))
            path.addLine(to: CGPoint(x: 0.25 * width, y: 0.125 * height))
            path.move(to: CGPoint(x: 0.21083 * width, y: 0.33333 * height))
            path.addCurve(to: CGPoint(x: 0.20833 * width, y: 0.33583 * height), control1: CGPoint(x: 0.20904 * width, y: 0.33333 * height), control2: CGPoint(x: 0.20833 * width, y: 0.33404 * height))
            path.addLine(to: CGPoint(x: 0.20833 * width, y: 0.83333 * height))
            path.addCurve(to: CGPoint(x: 0.29167 * width, y: 0.91667 * height), control1: CGPoint(x: 0.20833 * width, y: 0.87988 * height), control2: CGPoint(x: 0.24513 * width, y: 0.91667 * height))
            path.addLine(to: CGPoint(x: 0.70833 * width, y: 0.91667 * height))
            path.addCurve(to: CGPoint(x: 0.79167 * width, y: 0.83333 * height), control1: CGPoint(x: 0.75488 * width, y: 0.91667 * height), control2: CGPoint(x: 0.79167 * width, y: 0.87988 * height))
            path.addLine(to: CGPoint(x: 0.79167 * width, y: 0.33583 * height))
            path.addCurve(to: CGPoint(x: 0.78917 * width, y: 0.33333 * height), control1: CGPoint(x: 0.79167 * width, y: 0.33404 * height), control2: CGPoint(x: 0.79096 * width, y: 0.33333 * height))
            path.addLine(to: CGPoint(x: 0.21083 * width, y: 0.33333 * height))
            path.move(to: CGPoint(x: 0.39583 * width, y: 0.41667 * height))
            path.addCurve(to: CGPoint(x: 0.45833 * width, y: 0.47917 * height), control1: CGPoint(x: 0.43008 * width, y: 0.41667 * height), control2: CGPoint(x: 0.45833 * width, y: 0.44492 * height))
            path.addLine(to: CGPoint(x: 0.45833 * width, y: 0.77083 * height))
            path.addCurve(to: CGPoint(x: 0.39583 * width, y: 0.83333 * height), control1: CGPoint(x: 0.45833 * width, y: 0.80508 * height), control2: CGPoint(x: 0.43008 * width, y: 0.83333 * height))
            path.addCurve(to: CGPoint(x: 0.33333 * width, y: 0.77083 * height), control1: CGPoint(x: 0.36158 * width, y: 0.83333 * height), control2: CGPoint(x: 0.33333 * width, y: 0.80508 * height))
            path.addLine(to: CGPoint(x: 0.33333 * width, y: 0.47917 * height))
            path.addCurve(to: CGPoint(x: 0.39583 * width, y: 0.41667 * height), control1: CGPoint(x: 0.33333 * width, y: 0.44492 * height), control2: CGPoint(x: 0.36158 * width, y: 0.41667 * height))
            path.move(to: CGPoint(x: 0.60417 * width, y: 0.41667 * height))
            path.addCurve(to: CGPoint(x: 0.66667 * width, y: 0.47917 * height), control1: CGPoint(x: 0.63842 * width, y: 0.41667 * height), control2: CGPoint(x: 0.66667 * width, y: 0.44492 * height))
            path.addLine(to: CGPoint(x: 0.66667 * width, y: 0.77083 * height))
            path.addCurve(to: CGPoint(x: 0.60417 * width, y: 0.83333 * height), control1: CGPoint(x: 0.66667 * width, y: 0.80508 * height), control2: CGPoint(x: 0.63842 * width, y: 0.83333 * height))
            path.addCurve(to: CGPoint(x: 0.54167 * width, y: 0.77083 * height), control1: CGPoint(x: 0.56992 * width, y: 0.83333 * height), control2: CGPoint(x: 0.54167 * width, y: 0.80508 * height))
            path.addLine(to: CGPoint(x: 0.54167 * width, y: 0.47917 * height))
            path.addCurve(to: CGPoint(x: 0.60417 * width, y: 0.41667 * height), control1: CGPoint(x: 0.54167 * width, y: 0.44492 * height), control2: CGPoint(x: 0.56992 * width, y: 0.41667 * height))
            path.move(to: CGPoint(x: 0.39583 * width, y: 0.45833 * height))
            path.addCurve(to: CGPoint(x: 0.375 * width, y: 0.47917 * height), control1: CGPoint(x: 0.38392 * width, y: 0.45833 * height), control2: CGPoint(x: 0.375 * width, y: 0.46725 * height))
            path.addLine(to: CGPoint(x: 0.375 * width, y: 0.77083 * height))
            path.addCurve(to: CGPoint(x: 0.38098 * width, y: 0.78569 * height), control1: CGPoint(x: 0.37489 * width, y: 0.77639 * height), control2: CGPoint(x: 0.37704 * width, y: 0.78176 * height))
            path.addCurve(to: CGPoint(x: 0.39583 * width, y: 0.79167 * height), control1: CGPoint(x: 0.38491 * width, y: 0.78962 * height), control2: CGPoint(x: 0.39027 * width, y: 0.79178 * height))
            path.addCurve(to: CGPoint(x: 0.41667 * width, y: 0.77083 * height), control1: CGPoint(x: 0.40775 * width, y: 0.79167 * height), control2: CGPoint(x: 0.41667 * width, y: 0.78275 * height))
            path.addLine(to: CGPoint(x: 0.41667 * width, y: 0.47917 * height))
            path.addCurve(to: CGPoint(x: 0.39583 * width, y: 0.45833 * height), control1: CGPoint(x: 0.41667 * width, y: 0.46725 * height), control2: CGPoint(x: 0.40775 * width, y: 0.45833 * height))
            path.move(to: CGPoint(x: 0.60417 * width, y: 0.45833 * height))
            path.addCurve(to: CGPoint(x: 0.58333 * width, y: 0.47917 * height), control1: CGPoint(x: 0.59225 * width, y: 0.45833 * height), control2: CGPoint(x: 0.58333 * width, y: 0.46725 * height))
            path.addLine(to: CGPoint(x: 0.58333 * width, y: 0.77083 * height))
            path.addCurve(to: CGPoint(x: 0.58931 * width, y: 0.78569 * height), control1: CGPoint(x: 0.58322 * width, y: 0.77639 * height), control2: CGPoint(x: 0.58538 * width, y: 0.78176 * height))
            path.addCurve(to: CGPoint(x: 0.60417 * width, y: 0.79167 * height), control1: CGPoint(x: 0.59324 * width, y: 0.78962 * height), control2: CGPoint(x: 0.59861 * width, y: 0.79178 * height))
            path.addCurve(to: CGPoint(x: 0.625 * width, y: 0.77083 * height), control1: CGPoint(x: 0.61608 * width, y: 0.79167 * height), control2: CGPoint(x: 0.625 * width, y: 0.78275 * height))
            path.addLine(to: CGPoint(x: 0.625 * width, y: 0.47917 * height))
            path.addCurve(to: CGPoint(x: 0.60417 * width, y: 0.45833 * height), control1: CGPoint(x: 0.625 * width, y: 0.46725 * height), control2: CGPoint(x: 0.61608 * width, y: 0.45833 * height))
            return path
        }
    }
}

/// The icon for a spam folder, drawn as two stacked layers: a solid shape and a second shape at 20% opacity.
struct SpamIcon: View {
    /// Whether to draw the icon in the accent color instead of black.
    var tinted: Bool = false
    var body: some View {
        ZStack {
            ZStack {
                ZStack {
                    Layer0().fill(tinted ? .accent : .black).stroke(tinted ? .accent : .clear)
                }
                .compositingGroup()
                .opacity(0.2)
                ZStack {
                    Layer1().fill(tinted ? .accent : .black).stroke(tinted ? .accent : .clear)
                }
            }
        }
    }

    private struct Layer0: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width = rect.size.width
            let height = rect.size.height
            path.move(to: CGPoint(x: 0.45833 * width, y: 0.0625 * height))
            path.addCurve(to: CGPoint(x: 0.58333 * width, y: 0.9375 * height), control1: CGPoint(x: 1.03146 * width, y: 0.29933 * height), control2: CGPoint(x: 0.84233 * width, y: 0.86992 * height))
            path.addCurve(to: CGPoint(x: 0.5 * width, y: 0.6875 * height), control1: CGPoint(x: 0.67608 * width, y: 0.78083 * height), control2: CGPoint(x: 0.59904 * width, y: 0.685 * height))
            path.addCurve(to: CGPoint(x: 0.41667 * width, y: 0.9375 * height), control1: CGPoint(x: 0.40075 * width, y: 0.68517 * height), control2: CGPoint(x: 0.32412 * width, y: 0.78596 * height))
            path.addCurve(to: CGPoint(x: 0.29167 * width, y: 0.22917 * height), control1: CGPoint(x: 0.22679 * width, y: 0.9125 * height), control2: CGPoint(x: 0.03271 * width, y: 0.51638 * height))
            path.addCurve(to: CGPoint(x: 0.39583 * width, y: 0.4375 * height), control1: CGPoint(x: 0.26733 * width, y: 0.39929 * height), control2: CGPoint(x: 0.33333 * width, y: 0.4375 * height))
            path.addCurve(to: CGPoint(x: 0.45833 * width, y: 0.0625 * height), control1: CGPoint(x: 0.52083 * width, y: 0.4375 * height), control2: CGPoint(x: 0.52679 * width, y: 0.19554 * height))
            return path
        }
    }

    private struct Layer1: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width = rect.size.width
            let height = rect.size.height
            path.move(to: CGPoint(x: 0.46629 * width, y: 0.04321 * height))
            path.addCurve(to: CGPoint(x: 0.58863 * width, y: 0.95767 * height), control1: CGPoint(x: 1.05183 * width, y: 0.28517 * height), control2: CGPoint(x: 0.87296 * width, y: 0.8835 * height))
            path.addCurve(to: CGPoint(x: 0.56676 * width, y: 0.95006 * height), control1: CGPoint(x: 0.58047 * width, y: 0.95979 * height), control2: CGPoint(x: 0.57184 * width, y: 0.95679 * height))
            path.addCurve(to: CGPoint(x: 0.56542 * width, y: 0.92696 * height), control1: CGPoint(x: 0.56168 * width, y: 0.94334 * height), control2: CGPoint(x: 0.56115 * width, y: 0.93422 * height))
            path.addCurve(to: CGPoint(x: 0.59475 * width, y: 0.76154 * height), control1: CGPoint(x: 0.60958 * width, y: 0.85238 * height), control2: CGPoint(x: 0.61108 * width, y: 0.79683 * height))
            path.addCurve(to: CGPoint(x: 0.50058 * width, y: 0.70833 * height), control1: CGPoint(x: 0.57837 * width, y: 0.72629 * height), control2: CGPoint(x: 0.54325 * width, y: 0.70725 * height))
            path.addLine(to: CGPoint(x: 0.49954 * width, y: 0.70833 * height))
            path.addCurve(to: CGPoint(x: 0.40538 * width, y: 0.76342 * height), control1: CGPoint(x: 0.45704 * width, y: 0.70733 * height), control2: CGPoint(x: 0.42179 * width, y: 0.72738 * height))
            path.addCurve(to: CGPoint(x: 0.43442 * width, y: 0.92667 * height), control1: CGPoint(x: 0.38892 * width, y: 0.79946 * height), control2: CGPoint(x: 0.39054 * width, y: 0.85483 * height))
            path.addCurve(to: CGPoint(x: 0.4341 * width, y: 0.94883 * height), control1: CGPoint(x: 0.43858 * width, y: 0.9335 * height), control2: CGPoint(x: 0.43846 * width, y: 0.94212 * height))
            path.addCurve(to: CGPoint(x: 0.414 * width, y: 0.95817 * height), control1: CGPoint(x: 0.42975 * width, y: 0.95554 * height), control2: CGPoint(x: 0.42194 * width, y: 0.95917 * height))
            path.addCurve(to: CGPoint(x: 0.16583 * width, y: 0.68742 * height), control1: CGPoint(x: 0.30583 * width, y: 0.94396 * height), control2: CGPoint(x: 0.20742 * width, y: 0.83133 * height))
            path.addCurve(to: CGPoint(x: 0.27621 * width, y: 0.21525 * height), control1: CGPoint(x: 0.12429 * width, y: 0.5435 * height), control2: CGPoint(x: 0.14179 * width, y: 0.36429 * height))
            path.addCurve(to: CGPoint(x: 0.30042 * width, y: 0.21041 * height), control1: CGPoint(x: 0.28235 * width, y: 0.20851 * height), control2: CGPoint(x: 0.29216 * width, y: 0.20655 * height))
            path.addCurve(to: CGPoint(x: 0.31225 * width, y: 0.23208 * height), control1: CGPoint(x: 0.30868 * width, y: 0.21427 * height), control2: CGPoint(x: 0.31348 * width, y: 0.22305 * height))
            path.addCurve(to: CGPoint(x: 0.32829 * width, y: 0.38533 * height), control1: CGPoint(x: 0.3005 * width, y: 0.31433 * height), control2: CGPoint(x: 0.31146 * width, y: 0.36092 * height))
            path.addCurve(to: CGPoint(x: 0.39583 * width, y: 0.41667 * height), control1: CGPoint(x: 0.34512 * width, y: 0.40975 * height), control2: CGPoint(x: 0.36883 * width, y: 0.41667 * height))
            path.addCurve(to: CGPoint(x: 0.45083 * width, y: 0.38583 * height), control1: CGPoint(x: 0.42037 * width, y: 0.41667 * height), control2: CGPoint(x: 0.43667 * width, y: 0.40637 * height))
            path.addCurve(to: CGPoint(x: 0.47896 * width, y: 0.29762 * height), control1: CGPoint(x: 0.46504 * width, y: 0.36525 * height), control2: CGPoint(x: 0.47492 * width, y: 0.33387 * height))
            path.addCurve(to: CGPoint(x: 0.43979 * width, y: 0.07204 * height), control1: CGPoint(x: 0.48696 * width, y: 0.22508 * height), control2: CGPoint(x: 0.47154 * width, y: 0.13375 * height))
            path.addCurve(to: CGPoint(x: 0.44294 * width, y: 0.04834 * height), control1: CGPoint(x: 0.43575 * width, y: 0.06427 * height), control2: CGPoint(x: 0.43701 * width, y: 0.05479 * height))
            path.addCurve(to: CGPoint(x: 0.46629 * width, y: 0.04321 * height), control1: CGPoint(x: 0.44887 * width, y: 0.04189 * height), control2: CGPoint(x: 0.4582 * width, y: 0.03984 * height))
            path.move(to: CGPoint(x: 0.49421 * width, y: 0.10663 * height))
            path.addCurve(to: CGPoint(x: 0.52033 * width, y: 0.30217 * height), control1: CGPoint(x: 0.51542 * width, y: 0.16917 * height), control2: CGPoint(x: 0.52742 * width, y: 0.23858 * height))
            path.addCurve(to: CGPoint(x: 0.48513 * width, y: 0.40942 * height), control1: CGPoint(x: 0.51579 * width, y: 0.34304 * height), control2: CGPoint(x: 0.50508 * width, y: 0.38046 * height))
            path.addCurve(to: CGPoint(x: 0.39583 * width, y: 0.45833 * height), control1: CGPoint(x: 0.46517 * width, y: 0.43838 * height), control2: CGPoint(x: 0.43379 * width, y: 0.45833 * height))
            path.addCurve(to: CGPoint(x: 0.29404 * width, y: 0.40892 * height), control1: CGPoint(x: 0.36033 * width, y: 0.45833 * height), control2: CGPoint(x: 0.31971 * width, y: 0.44617 * height))
            path.addCurve(to: CGPoint(x: 0.26913 * width, y: 0.29838 * height), control1: CGPoint(x: 0.27671 * width, y: 0.38388 * height), control2: CGPoint(x: 0.27004 * width, y: 0.34492 * height))
            path.addCurve(to: CGPoint(x: 0.20592 * width, y: 0.67588 * height), control1: CGPoint(x: 0.18438 * width, y: 0.42338 * height), control2: CGPoint(x: 0.17258 * width, y: 0.56067 * height))
            path.addCurve(to: CGPoint(x: 0.38133 * width, y: 0.90242 * height), control1: CGPoint(x: 0.23825 * width, y: 0.78796 * height), control2: CGPoint(x: 0.31033 * width, y: 0.87183 * height))
            path.addCurve(to: CGPoint(x: 0.36742 * width, y: 0.74617 * height), control1: CGPoint(x: 0.35608 * width, y: 0.84233 * height), control2: CGPoint(x: 0.34871 * width, y: 0.78721 * height))
            path.addCurve(to: CGPoint(x: 0.5 * width, y: 0.66683 * height), control1: CGPoint(x: 0.39092 * width, y: 0.69467 * height), control2: CGPoint(x: 0.44342 * width, y: 0.66567 * height))
            path.addCurve(to: CGPoint(x: 0.6325 * width, y: 0.74404 * height), control1: CGPoint(x: 0.55617 * width, y: 0.66563 * height), control2: CGPoint(x: 0.60883 * width, y: 0.69304 * height))
            path.addCurve(to: CGPoint(x: 0.62129 * width, y: 0.89496 * height), control1: CGPoint(x: 0.65067 * width, y: 0.78329 * height), control2: CGPoint(x: 0.64388 * width, y: 0.83642 * height))
            path.addCurve(to: CGPoint(x: 0.49421 * width, y: 0.10663 * height), control1: CGPoint(x: 0.82613 * width, y: 0.787 * height), control2: CGPoint(x: 0.95954 * width, y: 0.33313 * height))
            return path
        }
    }
}

/// The icon for a generic folder, drawn as two stacked layers: a solid shape and a second shape at 20% opacity.
struct FolderIcon: View {
    /// Whether to draw the icon in the accent color instead of black.
    var tinted: Bool = false
    var body: some View {
        ZStack {
            ZStack {
                ZStack {
                    Layer0().fill(tinted ? .accent : .black).stroke(tinted ? .accent : .clear)
                }
                .compositingGroup()
                .opacity(0.2)
                ZStack {
                    Layer1().fill(tinted ? .accent : .black).stroke(tinted ? .accent : .clear)
                }
            }
        }
    }

    private struct Layer0: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width = rect.size.width
            let height = rect.size.height
            path.move(to: CGPoint(x: 0.16667 * width, y: 0.14583 * height))
            path.addLine(to: CGPoint(x: 0.4375 * width, y: 0.14583 * height))
            path.addLine(to: CGPoint(x: 0.52083 * width, y: 0.3125 * height))
            path.addLine(to: CGPoint(x: 0.83333 * width, y: 0.3125 * height))
            path.addCurve(to: CGPoint(x: 0.9375 * width, y: 0.41667 * height), control1: CGPoint(x: 0.89104 * width, y: 0.3125 * height), control2: CGPoint(x: 0.9375 * width, y: 0.35896 * height))
            path.addLine(to: CGPoint(x: 0.9375 * width, y: 0.75 * height))
            path.addCurve(to: CGPoint(x: 0.83333 * width, y: 0.85417 * height), control1: CGPoint(x: 0.9375 * width, y: 0.80771 * height), control2: CGPoint(x: 0.89104 * width, y: 0.85417 * height))
            path.addLine(to: CGPoint(x: 0.16667 * width, y: 0.85417 * height))
            path.addCurve(to: CGPoint(x: 0.09295 * width, y: 0.82372 * height), control1: CGPoint(x: 0.13902 * width, y: 0.85422 * height), control2: CGPoint(x: 0.1125 * width, y: 0.84327 * height))
            path.addCurve(to: CGPoint(x: 0.0625 * width, y: 0.75 * height), control1: CGPoint(x: 0.0734 * width, y: 0.80417 * height), control2: CGPoint(x: 0.06244 * width, y: 0.77764 * height))
            path.addLine(to: CGPoint(x: 0.0625 * width, y: 0.25 * height))
            path.addCurve(to: CGPoint(x: 0.16667 * width, y: 0.14583 * height), control1: CGPoint(x: 0.0625 * width, y: 0.19229 * height), control2: CGPoint(x: 0.10896 * width, y: 0.14583 * height))
            return path
        }
    }

    private struct Layer1: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width = rect.size.width
            let height = rect.size.height
            path.move(to: CGPoint(x: 0.4375 * width, y: 0.125 * height))
            path.addCurve(to: CGPoint(x: 0.45612 * width, y: 0.13654 * height), control1: CGPoint(x: 0.44539 * width, y: 0.12501 * height), control2: CGPoint(x: 0.4526 * width, y: 0.12948 * height))
            path.addLine(to: CGPoint(x: 0.47121 * width, y: 0.16667 * height))
            path.addLine(to: CGPoint(x: 0.83333 * width, y: 0.16667 * height))
            path.addCurve(to: CGPoint(x: 0.95833 * width, y: 0.29167 * height), control1: CGPoint(x: 0.90221 * width, y: 0.16667 * height), control2: CGPoint(x: 0.95833 * width, y: 0.22279 * height))
            path.addLine(to: CGPoint(x: 0.95833 * width, y: 0.75 * height))
            path.addCurve(to: CGPoint(x: 0.83333 * width, y: 0.875 * height), control1: CGPoint(x: 0.95833 * width, y: 0.81887 * height), control2: CGPoint(x: 0.90221 * width, y: 0.875 * height))
            path.addLine(to: CGPoint(x: 0.16667 * width, y: 0.875 * height))
            path.addCurve(to: CGPoint(x: 0.04167 * width, y: 0.75 * height), control1: CGPoint(x: 0.09779 * width, y: 0.875 * height), control2: CGPoint(x: 0.04167 * width, y: 0.81887 * height))
            path.addLine(to: CGPoint(x: 0.04167 * width, y: 0.25 * height))
            path.addCurve(to: CGPoint(x: 0.16667 * width, y: 0.125 * height), control1: CGPoint(x: 0.04167 * width, y: 0.18113 * height), control2: CGPoint(x: 0.09779 * width, y: 0.125 * height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.16667 * width, y: 0.16667 * height))
            path.addCurve(to: CGPoint(x: 0.08333 * width, y: 0.25 * height), control1: CGPoint(x: 0.12012 * width, y: 0.16667 * height), control2: CGPoint(x: 0.08333 * width, y: 0.20346 * height))
            path.addLine(to: CGPoint(x: 0.08333 * width, y: 0.29167 * height))
            path.addLine(to: CGPoint(x: 0.3125 * width, y: 0.29167 * height))
            path.addCurve(to: CGPoint(x: 0.33333 * width, y: 0.3125 * height), control1: CGPoint(x: 0.32401 * width, y: 0.29167 * height), control2: CGPoint(x: 0.33333 * width, y: 0.30099 * height))
            path.addCurve(to: CGPoint(x: 0.3125 * width, y: 0.33333 * height), control1: CGPoint(x: 0.33333 * width, y: 0.32401 * height), control2: CGPoint(x: 0.32401 * width, y: 0.33333 * height))
            path.addLine(to: CGPoint(x: 0.08333 * width, y: 0.33333 * height))
            path.addLine(to: CGPoint(x: 0.08333 * width, y: 0.75 * height))
            path.addCurve(to: CGPoint(x: 0.16667 * width, y: 0.83333 * height), control1: CGPoint(x: 0.08333 * width, y: 0.79654 * height), control2: CGPoint(x: 0.12012 * width, y: 0.83333 * height))
            path.addLine(to: CGPoint(x: 0.83333 * width, y: 0.83333 * height))
            path.addCurve(to: CGPoint(x: 0.91667 * width, y: 0.75 * height), control1: CGPoint(x: 0.87988 * width, y: 0.83333 * height), control2: CGPoint(x: 0.91667 * width, y: 0.79654 * height))
            path.addLine(to: CGPoint(x: 0.91667 * width, y: 0.41667 * height))
            path.addCurve(to: CGPoint(x: 0.83333 * width, y: 0.33333 * height), control1: CGPoint(x: 0.91667 * width, y: 0.37012 * height), control2: CGPoint(x: 0.87988 * width, y: 0.33333 * height))
            path.addLine(to: CGPoint(x: 0.52083 * width, y: 0.33333 * height))
            path.addCurve(to: CGPoint(x: 0.50221 * width, y: 0.32187 * height), control1: CGPoint(x: 0.51296 * width, y: 0.33334 * height), control2: CGPoint(x: 0.50575 * width, y: 0.32891 * height))
            path.addLine(to: CGPoint(x: 0.43904 * width, y: 0.19546 * height))
            path.addLine(to: CGPoint(x: 0.42462 * width, y: 0.16667 * height))
            path.addLine(to: CGPoint(x: 0.16667 * width, y: 0.16667 * height))
            path.move(to: CGPoint(x: 0.53371 * width, y: 0.29167 * height))
            path.addLine(to: CGPoint(x: 0.83333 * width, y: 0.29167 * height))
            path.addCurve(to: CGPoint(x: 0.91667 * width, y: 0.32379 * height), control1: CGPoint(x: 0.86413 * width, y: 0.29167 * height), control2: CGPoint(x: 0.89383 * width, y: 0.30312 * height))
            path.addLine(to: CGPoint(x: 0.91667 * width, y: 0.29167 * height))
            path.addCurve(to: CGPoint(x: 0.83333 * width, y: 0.20833 * height), control1: CGPoint(x: 0.91667 * width, y: 0.24513 * height), control2: CGPoint(x: 0.87988 * width, y: 0.20833 * height))
            path.addLine(to: CGPoint(x: 0.49204 * width, y: 0.20833 * height))
            path.closeSubpath()
            return path
        }
    }
}

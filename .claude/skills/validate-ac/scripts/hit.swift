// Prints the owners of the on-screen windows under a point, front-most first: `hit X Y`
import CoreGraphics
import Foundation

let x = Double(CommandLine.arguments[1])!
let y = Double(CommandLine.arguments[2])!
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]
for w in list {
    guard (w[kCGWindowAlpha as String] as? Double ?? 1) > 0.01,
        let b = w[kCGWindowBounds as String] as? [String: Double]
    else { continue }
    let r = CGRect(x: b["X"]!, y: b["Y"]!, width: b["Width"]!, height: b["Height"]!)
    if r.contains(CGPoint(x: x, y: y)) {
        print("\(w[kCGWindowOwnerName as String] as? String ?? "?") layer=\(w[kCGWindowLayer as String] ?? "?")")
    }
}

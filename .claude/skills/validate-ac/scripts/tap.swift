// Sends a real left mouse click at a screen point: `tap X Y`. Needs Accessibility permission.
import CoreGraphics
import Foundation

let p = CGPoint(x: Double(CommandLine.arguments[1])!, y: Double(CommandLine.arguments[2])!)
CGWarpMouseCursorPosition(p)
usleep(150_000)
for t in [CGEventType.leftMouseDown, .leftMouseUp] {
    CGEvent(mouseEventSource: nil, mouseType: t, mouseCursorPosition: p, mouseButton: .left)?.post(tap: .cghidEventTap)
    usleep(80_000)
}

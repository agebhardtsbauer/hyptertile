import Foundation
import AppKit
import CoreGraphics

class BorderWindow: NSWindow {
    private let borderWidth: CGFloat = 2
    private let borderColor: NSColor = NSColor.cyan

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.backgroundColor = .clear
        self.isOpaque = false
        self.level = .floating
        self.ignoresMouseEvents = true
        self.hasShadow = false
        self.isReleasedWhenClosed = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        setupBorderView()
    }

    private func setupBorderView() {
        let borderView = BorderView(borderWidth: borderWidth, borderColor: borderColor)
        self.contentView = borderView
    }

    func updateFrame(for windowFrame: CGRect) {
        // Convert from Accessibility API coordinates (top-left origin, Y increases down)
        // to NSWindow coordinates (bottom-left origin, Y increases up)
        guard let screen = NSScreen.main else { return }

        let screenHeight = screen.frame.height
        let convertedY = screenHeight - windowFrame.origin.y - windowFrame.height

        var convertedFrame = windowFrame
        convertedFrame.origin.y = convertedY

        let inset = -borderWidth / 2
        let borderFrame = convertedFrame.insetBy(dx: inset, dy: inset)
        self.setFrame(borderFrame, display: true, animate: false)
    }

    func show() {
        self.orderFront(nil)
    }

    func hide() {
        self.orderOut(nil)
    }
}

class BorderView: NSView {
    private let borderWidth: CGFloat
    private let borderColor: NSColor

    init(borderWidth: CGFloat, borderColor: NSColor) {
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Clear background
        context.clear(bounds)

        // Draw border
        borderColor.setStroke()
        let borderPath = NSBezierPath(rect: bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2))
        borderPath.lineWidth = borderWidth
        borderPath.stroke()
    }
}

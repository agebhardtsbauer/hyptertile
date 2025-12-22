import Foundation
import AppKit
import ApplicationServices
import CoreGraphics

class WindowManager {
    private let appState: AppState
    private let config: Config
    private let borderWindow: BorderWindow
    private var focusObserver: Any?

    init(appState: AppState, config: Config) {
        self.appState = appState
        self.config = config
        self.borderWindow = BorderWindow()

        setupFocusMonitoring()
    }

    deinit {
        if let observer = focusObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    private func setupFocusMonitoring() {
        focusObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateBorder()
        }

        // Initial border update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateBorder()
        }
    }

    func updateBorder() {
        guard let window = getFrontmostWindow(),
              let windowFrame = getWindowFrame(window) else {
            borderWindow.hide()
            return
        }

        borderWindow.updateFrame(for: windowFrame)
        borderWindow.show()
    }

    func launchAndFocusApp(_ appName: String) -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        let targetApp = runningApps.first { $0.localizedName == appName }

        if targetApp == nil {
            print("Application \(appName) is not running.")
            return false
        }

        guard let app = targetApp else {
            print("Could not find application: \(appName)")
            return false
        }

        if app.isHidden {
            app.unhide()
        }

        app.activate(options: [.activateIgnoringOtherApps])

        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier != app.bundleIdentifier {
            let script = """
            tell application "\(appName)"
                activate
            end tell
            """

            let appleScript = Process()
            appleScript.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            appleScript.arguments = ["-e", script]

            do {
                try appleScript.run()
                appleScript.waitUntilExit()
                Thread.sleep(forTimeInterval: 0.2)
            } catch {
            }
        }

        return true
    }


    func getScreenFrame() -> CGRect {
        guard let screen = NSScreen.main else {
            return CGRect.zero
        }
        return screen.visibleFrame
    }

    func getFrontmostWindow() -> AXUIElement? {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedApp: AnyObject?

        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedApplicationAttribute as CFString, &focusedApp)

        guard result == .success, let appElement = focusedApp else {
            return nil
        }

        var focusedWindow: AnyObject?
        let windowResult = AXUIElementCopyAttributeValue(appElement as! AXUIElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)

        guard windowResult == .success else {
            return nil
        }

        return (focusedWindow as! AXUIElement)
    }

    func setWindowFrame(_ window: AXUIElement, frame: CGRect) {
        var position = CGPoint(x: frame.origin.x, y: frame.origin.y)
        var size = CGSize(width: frame.size.width, height: frame.size.height)

        let positionValue = AXValueCreate(.cgPoint, &position)!
        let sizeValue = AXValueCreate(.cgSize, &size)!

        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
    }

    func getWindowFrame(_ window: AXUIElement) -> CGRect? {
        var positionRef: AnyObject?
        var sizeRef: AnyObject?

        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success else {
            return nil
        }

        var position = CGPoint.zero
        var size = CGSize.zero

        AXValueGetValue(positionRef as! AXValue, .cgPoint, &position)
        AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)

        return CGRect(origin: position, size: size)
    }

    func positionWindow(to position: WindowPosition, for appName: String, centeredWidth: Int) -> CGRect? {
        guard let window = getFrontmostWindow() else {
            print("Could not get frontmost window")
            return nil
        }

        let screenFrame = getScreenFrame()
        let newFrame: CGRect

        switch position {
        case .left:
            newFrame = CGRect(
                x: screenFrame.origin.x,
                y: screenFrame.origin.y,
                width: screenFrame.width / 2,
                height: screenFrame.height
            )

        case .right:
            newFrame = CGRect(
                x: screenFrame.origin.x + screenFrame.width / 2,
                y: screenFrame.origin.y,
                width: screenFrame.width / 2,
                height: screenFrame.height
            )

        case .centered:
            let widthPercent = CGFloat(centeredWidth) / 100.0
            let windowWidth = screenFrame.width * widthPercent
            let leftGap = (screenFrame.width - windowWidth) / 2

            newFrame = CGRect(
                x: screenFrame.origin.x + leftGap,
                y: screenFrame.origin.y,
                width: windowWidth,
                height: screenFrame.height
            )

            // Cache centered bounds
            appState.updateCenteredBounds(for: appName, bounds: newFrame)

        case .fullscreen:
            newFrame = CGRect(
                x: screenFrame.origin.x,
                y: screenFrame.origin.y,
                width: screenFrame.width,
                height: screenFrame.height
            )
        }

        setWindowFrame(window, frame: newFrame)
        appState.updatePosition(for: appName, position: position)
        appState.updateBounds(for: appName, bounds: newFrame)

        // Update border immediately with the new frame for instant visual feedback
        borderWindow.updateFrame(for: newFrame)
        borderWindow.show()

        return newFrame
    }

    func moveMouseToPosition(_ mousePos: MousePosition, in appName: String) {
        guard let window = getFrontmostWindow(),
              let windowFrame = getWindowFrame(window) else {
            return
        }

        moveMouseToPosition(mousePos, in: windowFrame)
    }

    func moveMouseToPosition(_ mousePos: MousePosition, in frame: CGRect) {
        let xPercent = CGFloat(mousePos.x) / 100.0
        let yPercent = CGFloat(mousePos.y) / 100.0

        let absoluteX = frame.origin.x + (frame.width * xPercent)
        let absoluteY = frame.origin.y + (frame.height * yPercent)

        let newPosition = CGPoint(x: absoluteX, y: absoluteY)

        CGWarpMouseCursorPosition(newPosition)
    }

    func calculateAndCacheMousePosition(for appName: String, mousePercent: MousePosition, in frame: CGRect) {
        let xPercent = CGFloat(mousePercent.x) / 100.0
        let yPercent = CGFloat(mousePercent.y) / 100.0

        let absoluteX = frame.origin.x + (frame.width * xPercent)
        let absoluteY = frame.origin.y + (frame.height * yPercent)

        let absolutePosition = CGPoint(x: absoluteX, y: absoluteY)
        appState.updateCachedMousePosition(for: appName, position: absolutePosition)
    }

    func warpToCachedMousePosition(for appName: String) {
        if let cachedPosition = appState.getCachedMousePosition(for: appName) {
            CGWarpMouseCursorPosition(cachedPosition)
        }
    }

    func detectActualWindowPosition(frame: CGRect, centeredWidth: Int) -> WindowPosition? {
        let screenFrame = getScreenFrame()
        let tolerance: CGFloat = 5.0 // Allow 5 pixel tolerance for floating point comparison

        // Check fullscreen (100% width and height)
        if abs(frame.width - screenFrame.width) < tolerance &&
           abs(frame.height - screenFrame.height) < tolerance {
            return .fullscreen
        }

        // Check left half
        if abs(frame.origin.x - screenFrame.origin.x) < tolerance &&
           abs(frame.width - screenFrame.width / 2) < tolerance {
            return .left
        }

        // Check right half
        if abs(frame.origin.x - (screenFrame.origin.x + screenFrame.width / 2)) < tolerance &&
           abs(frame.width - screenFrame.width / 2) < tolerance {
            return .right
        }

        // Check centered
        let expectedCenteredWidth = screenFrame.width * CGFloat(centeredWidth) / 100.0
        let expectedLeftGap = (screenFrame.width - expectedCenteredWidth) / 2
        if abs(frame.width - expectedCenteredWidth) < tolerance &&
           abs(frame.origin.x - (screenFrame.origin.x + expectedLeftGap)) < tolerance {
            return .centered
        }

        return nil
    }

    func handleAppBinding(_ binding: AppBinding) {
        // Get currently focused app
        guard let currentApp = NSWorkspace.shared.frontmostApplication,
              let currentAppName = currentApp.localizedName else {
            // If no current app, just focus the requested app
            if !launchAndFocusApp(binding.appName) {
                return
            }

            // Calculate and cache mouse position for the focused app's current frame
            if let mousePos = binding.mousePosition,
               let window = getFrontmostWindow(),
               let windowFrame = getWindowFrame(window) {
                calculateAndCacheMousePosition(for: binding.appName, mousePercent: mousePos, in: windowFrame)
            }
            warpToCachedMousePosition(for: binding.appName)
            updateBorder()
            return
        }

        // If the pressed app is already active, toggle it
        if currentAppName == binding.appName {
            let centeredWidth = config.getCenteredWidth(for: binding)

            // Detect actual window position instead of relying on cached state
            guard let window = getFrontmostWindow(),
                  let windowFrame = getWindowFrame(window) else {
                return
            }

            let actualPosition = detectActualWindowPosition(frame: windowFrame, centeredWidth: centeredWidth)

            let newFrame: CGRect?
            if actualPosition == .centered {
                // Move to last half side (default to left if unknown)
                let targetPosition = appState.getLastHalfSide(for: currentAppName) ?? .left
                newFrame = positionWindow(to: targetPosition, for: currentAppName, centeredWidth: centeredWidth)
            } else {
                // Move to centered
                newFrame = positionWindow(to: .centered, for: currentAppName, centeredWidth: centeredWidth)
            }

            if let mousePos = binding.mousePosition, let frame = newFrame {
                calculateAndCacheMousePosition(for: currentAppName, mousePercent: mousePos, in: frame)
            }
            warpToCachedMousePosition(for: currentAppName)
            updateBorder()
            return
        }

        // Return current app to its last half side if it's centered or fullscreen
        if let currentBinding = config.apps.first(where: { $0.appName == currentAppName }),
           let window = getFrontmostWindow(),
           let windowFrame = getWindowFrame(window) {
            let centeredWidth = config.getCenteredWidth(for: currentBinding)
            let actualPosition = detectActualWindowPosition(frame: windowFrame, centeredWidth: centeredWidth)

            if actualPosition == .centered || actualPosition == .fullscreen {
                let targetPosition = appState.getLastHalfSide(for: currentAppName) ?? .left
                _ = positionWindow(to: targetPosition, for: currentAppName, centeredWidth: centeredWidth)
            }
        }

        // Focus the requested app
        if !launchAndFocusApp(binding.appName) {
            return
        }

        // Always recalculate mouse position based on actual window frame after focusing
        if let mousePos = binding.mousePosition,
           let window = getFrontmostWindow(),
           let windowFrame = getWindowFrame(window) {
            calculateAndCacheMousePosition(for: binding.appName, mousePercent: mousePos, in: windowFrame)
            warpToCachedMousePosition(for: binding.appName)
        }
        updateBorder()
    }

    func handleSwapKey() {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              let appName = frontmostApp.localizedName else {
            print("Could not get frontmost application")
            return
        }

        guard let binding = config.apps.first(where: { $0.appName == appName }) else {
            print("No binding found for application: \(appName)")
            return
        }

        let currentPosition = appState.getPosition(for: appName)
        let centeredWidth = config.getCenteredWidth(for: binding)

        let newFrame: CGRect?
        switch currentPosition {
        case .left:
            // Move to right
            newFrame = positionWindow(to: .right, for: appName, centeredWidth: centeredWidth)

        case .right:
            // Move to left
            newFrame = positionWindow(to: .left, for: appName, centeredWidth: centeredWidth)

        case .centered, .fullscreen, nil:
            // Return to opposite of last half side
            let lastHalf = appState.getLastHalfSide(for: appName)
            let targetPosition: WindowPosition
            if lastHalf == .left {
                targetPosition = .right
            } else if lastHalf == .right {
                targetPosition = .left
            } else {
                // Default to left if unknown
                targetPosition = .left
            }
            newFrame = positionWindow(to: targetPosition, for: appName, centeredWidth: centeredWidth)
        }

        if let mousePos = binding.mousePosition, let frame = newFrame {
            calculateAndCacheMousePosition(for: appName, mousePercent: mousePos, in: frame)
        }
        warpToCachedMousePosition(for: appName)
        updateBorder()
    }

    func handleFullscreenKey() {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              let appName = frontmostApp.localizedName else {
            print("Could not get frontmost application")
            return
        }

        guard let binding = config.apps.first(where: { $0.appName == appName }) else {
            print("No binding found for application: \(appName)")
            return
        }

        let currentPosition = appState.getPosition(for: appName)
        let centeredWidth = config.getCenteredWidth(for: binding)

        let newFrame: CGRect?
        if currentPosition == .fullscreen {
            // Return to previous position
            if let previousPosition = appState.getPreviousPosition(for: appName) {
                newFrame = positionWindow(to: previousPosition, for: appName, centeredWidth: centeredWidth)
            } else {
                // Default to left if no previous position
                newFrame = positionWindow(to: .left, for: appName, centeredWidth: centeredWidth)
            }
        } else {
            // Go to fullscreen
            newFrame = positionWindow(to: .fullscreen, for: appName, centeredWidth: centeredWidth)
        }

        if let mousePos = binding.mousePosition, let frame = newFrame {
            calculateAndCacheMousePosition(for: appName, mousePercent: mousePos, in: frame)
        }
        warpToCachedMousePosition(for: appName)
        updateBorder()
    }
}

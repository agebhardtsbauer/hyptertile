import Foundation
import AppKit
import ApplicationServices
import CoreGraphics

class WindowManager {
    private let appState: AppState
    private let config: Config

    private let border: CGFloat = 6
    private let menuBarHeight: CGFloat = 25

    init(appState: AppState, config: Config) {
        self.appState = appState
        self.config = config
    }

    func launchAndFocusApp(_ appName: String) -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        var targetApp = runningApps.first { $0.localizedName == appName }

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
        // Thread.sleep(forTimeInterval: 0.10)

        // if NSWorkspace.shared.frontmostApplication?.bundleIdentifier != app.bundleIdentifier {
        //     let process = Process()
        //     process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        //     process.arguments = ["-a", appName]
        //
        //     do {
        //         try process.run()
        //         process.waitUntilExit()
        //         Thread.sleep(forTimeInterval: 0.15)
        //     } catch {
        //     }

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
        // }

        return true
    }

    private func findApplicationURL(named appName: String) -> URL? {
        let fileManager = FileManager.default
        let searchPaths = [
            "/Applications",
            "/System/Applications",
            "\(NSHomeDirectory())/Applications"
        ]

        for path in searchPaths {
            let appPath = "\(path)/\(appName).app"
            if fileManager.fileExists(atPath: appPath) {
                return URL(fileURLWithPath: appPath)
            }
        }

        return nil
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

    func positionWindow(to position: WindowPosition, for appName: String, centeredWidth: Int) {
        guard let window = getFrontmostWindow() else {
            print("Could not get frontmost window")
            return
        }

        let screenFrame = getScreenFrame()
        let newFrame: CGRect

        switch position {
        case .left:
            newFrame = CGRect(
                x: screenFrame.origin.x,
                y: screenFrame.origin.y + menuBarHeight,
                width: screenFrame.width / 2,
                height: screenFrame.height
            )

        case .right:
            newFrame = CGRect(
                x: screenFrame.origin.x + screenFrame.width / 2,
                y: screenFrame.origin.y + menuBarHeight,
                width: screenFrame.width / 2,
                height: screenFrame.height
            )

        case .centered:
            let widthPercent = CGFloat(centeredWidth) / 100.0
            let windowWidth = screenFrame.width * widthPercent
            let leftGap = (screenFrame.width - windowWidth) / 2

            newFrame = CGRect(
                x: screenFrame.origin.x + leftGap,
                y: screenFrame.origin.y + menuBarHeight,
                width: windowWidth,
                height: screenFrame.height
            )
        }

        setWindowFrame(window, frame: newFrame)
        appState.updatePosition(for: appName, position: position)
        appState.updateBounds(for: appName, bounds: newFrame)
    }

    func moveMouseToPosition(_ mousePos: MousePosition, in appName: String) {
        guard let window = getFrontmostWindow(),
              let windowFrame = getWindowFrame(window) else {
            return
        }

        let xPercent = CGFloat(mousePos.x) / 100.0
        let yPercent = CGFloat(mousePos.y) / 100.0

        let absoluteX = windowFrame.origin.x + (windowFrame.width * xPercent)
        let absoluteY = windowFrame.origin.y + (windowFrame.height * yPercent)

        let newPosition = CGPoint(x: absoluteX, y: absoluteY)

        CGWarpMouseCursorPosition(newPosition)
    }

    func handleAppBinding(_ binding: AppBinding) {
        if !launchAndFocusApp(binding.appName) {
            return
        }

        Thread.sleep(forTimeInterval: 0.1)

        if let mousePos = binding.mousePosition {
            moveMouseToPosition(mousePos, in: binding.appName)
        }
    }

    func handleLeftKey() {
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

        if currentPosition == .left {
            positionWindow(to: .centered, for: appName, centeredWidth: centeredWidth)
        } else {
            positionWindow(to: .left, for: appName, centeredWidth: centeredWidth)
        }
    }

    func handleRightKey() {
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

        if currentPosition == .right {
            positionWindow(to: .centered, for: appName, centeredWidth: centeredWidth)
        } else {
            positionWindow(to: .right, for: appName, centeredWidth: centeredWidth)
        }
    }
}

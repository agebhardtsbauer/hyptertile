import Foundation
import AppKit

func checkAccessibilityPermissions() -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
}

print("HyperTile - Fast and Opinionated Tiling Window Manager")
print("========================================================\n")

guard let config = Config.load() else {
    print("❌ Failed to load configuration")
    exit(1)
}

let mode = config.accessibilityMode ? "Full Mode" : "Lite Mode"
print("✓ Running in: \(mode)")
print("✓ Configuration loaded from: \(Config.defaultConfigPath)\n")

if config.accessibilityMode {
    if !checkAccessibilityPermissions() {
        print("⚠️  Accessibility permissions required for Full Mode!")
        print("Please grant accessibility permissions in System Settings.")
        print("Go to: System Settings > Privacy & Security > Accessibility")
        print("\nAlternatively, set \"accessibilityMode\": false in your config")
        print("to run in Lite Mode (app focus + mouse positioning only).\n")
        exit(1)
    }
    print("✓ Accessibility permissions granted")
    print("✓ Window tiling enabled (Hyper+\(config.left) / Hyper+\(config.right))\n")
} else {
    print("ℹ️  Lite Mode: Window tiling disabled")
    print("ℹ️  App focus and mouse positioning only\n")
}

let appState = AppState()
let windowManager = WindowManager(appState: appState, config: config)
let keyboardMonitor = KeyboardMonitor(config: config, windowManager: windowManager)

let signalHandler: @convention(c) (Int32) -> Void = { signal in
    print("\n\nShutting down HyperTile...")
    exit(0)
}

signal(SIGINT, signalHandler)
signal(SIGTERM, signalHandler)

keyboardMonitor.start()

RunLoop.main.run()

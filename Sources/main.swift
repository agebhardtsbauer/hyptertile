import Foundation
import AppKit

func checkAccessibilityPermissions() -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
}

print("HyperTile - Fast and Opinionated Tiling Window Manager")
print("========================================================\n")

if !checkAccessibilityPermissions() {
    print("⚠️  Accessibility permissions required!")
    print("Please grant accessibility permissions in System Settings.")
    print("Go to: System Settings > Privacy & Security > Accessibility")
    print("\nOnce granted, restart HyperTile.\n")
    exit(1)
}

guard let config = Config.load() else {
    print("❌ Failed to load configuration")
    exit(1)
}

print("✓ Configuration loaded from: \(Config.defaultConfigPath)")
print("✓ Accessibility permissions granted\n")

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

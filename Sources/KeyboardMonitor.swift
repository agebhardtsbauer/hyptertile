import Foundation
import CoreGraphics
import Carbon

class KeyboardMonitor {
    private let config: Config
    private let windowManager: WindowManager
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private let hyperModifiers: CGEventFlags = [
        .maskControl,
        .maskCommand,
        .maskShift,
        .maskAlternate
    ]

    init(config: Config, windowManager: WindowManager) {
        self.config = config
        self.windowManager = windowManager
    }

    func start() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passRetained(event)
                }

                let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon).takeUnretainedValue()
                return monitor.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap. Please grant Accessibility permissions.")
            print("Go to System Settings > Privacy & Security > Accessibility")
            return
        }

        self.eventTap = eventTap

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        self.runLoopSource = runLoopSource

        print("HyperTile is running...")
        print("Hyper = Ctrl + Cmd + Shift + Option\n")

        if config.accessibilityMode {
            print("Window Tiling:")
            print("  Hyper + \(config.left) -> Toggle left/center")
            print("  Hyper + \(config.right) -> Toggle right/center\n")
        }

        print("App Bindings:")
        for app in config.apps {
            print("  Hyper + \(app.bind) -> \(app.appName)")
        }
        print("\nPress Ctrl+C to quit")
    }

    func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .keyDown {
            let flags = event.flags
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

            if hasHyperModifiers(flags) {
                if let char = keyCodeToChar(keyCode) {
                    if handleKeyPress(char) {
                        return nil
                    }
                }
            }
        }

        return Unmanaged.passRetained(event)
    }

    private func hasHyperModifiers(_ flags: CGEventFlags) -> Bool {
        return flags.contains(.maskControl) &&
               flags.contains(.maskCommand) &&
               flags.contains(.maskShift) &&
               flags.contains(.maskAlternate)
    }

    private func handleKeyPress(_ char: String) -> Bool {
        let lowerChar = char.lowercased()

        if config.accessibilityMode {
            if lowerChar == config.left.lowercased() {
                DispatchQueue.main.async {
                    self.windowManager.handleLeftKey()
                }
                return true
            }

            if lowerChar == config.right.lowercased() {
                DispatchQueue.main.async {
                    self.windowManager.handleRightKey()
                }
                return true
            }
        }

        if let binding = config.findBinding(for: lowerChar) {
            DispatchQueue.main.async {
                self.windowManager.handleAppBinding(binding)
            }
            return true
        }

        return false
    }

    private func keyCodeToChar(_ keyCode: Int64) -> String? {
        let keyCodeMap: [Int64: String] = [
            0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g", 6: "z", 7: "x",
            8: "c", 9: "v", 11: "b", 12: "q", 13: "w", 14: "e", 15: "r",
            16: "y", 17: "t", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "o", 32: "u", 33: "[", 34: "i", 35: "p", 37: "l",
            38: "j", 39: "'", 40: "k", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "n", 46: "m", 47: ".", 50: "`"
        ]

        return keyCodeMap[keyCode]
    }
}

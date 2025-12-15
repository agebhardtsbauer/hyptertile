import Foundation
import CoreGraphics

enum WindowPosition {
    case left
    case right
    case centered
}

class AppWindowState {
    var position: WindowPosition?
    var bounds: CGRect?
    var isHidden: Bool = false

    init() {}
}

class AppState {
    private var windowStates: [String: AppWindowState] = [:]

    func getState(for appName: String) -> AppWindowState {
        if let state = windowStates[appName] {
            return state
        }
        let newState = AppWindowState()
        windowStates[appName] = newState
        return newState
    }

    func updatePosition(for appName: String, position: WindowPosition) {
        let state = getState(for: appName)
        state.position = position
    }

    func updateBounds(for appName: String, bounds: CGRect) {
        let state = getState(for: appName)
        state.bounds = bounds
    }

    func setHidden(for appName: String, hidden: Bool) {
        let state = getState(for: appName)
        state.isHidden = hidden
    }

    func isHidden(for appName: String) -> Bool {
        return getState(for: appName).isHidden
    }

    func getPosition(for appName: String) -> WindowPosition? {
        return getState(for: appName).position
    }
}

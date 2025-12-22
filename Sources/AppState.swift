import Foundation
import CoreGraphics

enum WindowPosition {
    case left
    case right
    case centered
    case fullscreen
}

class AppWindowState {
    var position: WindowPosition?
    var previousPosition: WindowPosition?
    var lastHalfSide: WindowPosition?
    var bounds: CGRect?
    var centeredBounds: CGRect?
    var cachedMousePosition: CGPoint?

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
        state.previousPosition = state.position
        state.position = position

        // Track last half side position
        if position == .left || position == .right {
            state.lastHalfSide = position
        }
    }

    func updateBounds(for appName: String, bounds: CGRect) {
        let state = getState(for: appName)
        state.bounds = bounds
    }

    func updateCenteredBounds(for appName: String, bounds: CGRect) {
        let state = getState(for: appName)
        state.centeredBounds = bounds
    }

    func getPosition(for appName: String) -> WindowPosition? {
        return getState(for: appName).position
    }

    func getPreviousPosition(for appName: String) -> WindowPosition? {
        return getState(for: appName).previousPosition
    }

    func getLastHalfSide(for appName: String) -> WindowPosition? {
        return getState(for: appName).lastHalfSide
    }

    func getCenteredBounds(for appName: String) -> CGRect? {
        return getState(for: appName).centeredBounds
    }

    func updateCachedMousePosition(for appName: String, position: CGPoint) {
        let state = getState(for: appName)
        state.cachedMousePosition = position
    }

    func getCachedMousePosition(for appName: String) -> CGPoint? {
        return getState(for: appName).cachedMousePosition
    }
}

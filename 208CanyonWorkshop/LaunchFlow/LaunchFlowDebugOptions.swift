//
//  LaunchFlowDebugOptions.swift
//  157Countdown
//

import Foundation

#if DEBUG
enum LaunchFlowDebugOverride: String, CaseIterable {
    case automatic
    case forceNative
    case forceWeb
    case forceStaging
}

enum LaunchFlowDebugOptions {
    private static let overrideKey = "launch_flow_debug_override"

    static var current: LaunchFlowDebugOverride {
        guard let raw = UserDefaults.standard.string(forKey: overrideKey),
              let value = LaunchFlowDebugOverride(rawValue: raw) else {
            return .automatic
        }
        return value
    }

    static func set(_ override: LaunchFlowDebugOverride) {
        UserDefaults.standard.set(override.rawValue, forKey: overrideKey)
    }
}
#endif

//
//  LaunchFlowLogger.swift
//  157Countdown
//

import Foundation
import os

enum LaunchFlowLogger {
    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LaunchFlow", category: "LaunchFlow")

    static func debug(_ message: String) {
        #if DEBUG
        log.debug("\(message, privacy: .public)")
        #endif
    }

    static func notice(_ message: String) {
        #if DEBUG
        log.notice("\(message, privacy: .public)")
        #endif
    }
}

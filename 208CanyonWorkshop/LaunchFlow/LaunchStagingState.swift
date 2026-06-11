//
//  LaunchStagingState.swift
//  157Countdown
//

import Combine
import Foundation

@MainActor
final class LaunchStagingState: ObservableObject {
    @Published var progress: Double = 0
    @Published var statusMessage: String = AppMarketingCopy.launchStagingMessage
}

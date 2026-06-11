//
//  LaunchDestination.swift
//  157Countdown
//

import Foundation

enum LaunchDestination: Equatable {
    case native
    case web(URL)
    case staging
}

//
//  AppMarketingCopy.swift
//  157Countdown
//
//  Positioning lines for in-app surfaces and App Store metadata (English).
//

import Foundation

enum AppMarketingCopy {
    /// Single strong positioning line — use in subtitle, onboarding, and store listing.
    static let positioningLine =
        "Your personal event timeline — with custom tags, daily inspiration, and calm offline countdowns."

    static let shortTagline = "Count down with your own labels."

    static let onboardingHeroSubtitle =
        "Track what matters on your timeline. Use built-in categories or create custom tags that fit your life — work, family, hobbies, anything."

    static let customTagsFeatureBlurb =
        "Label events with presets or your own tags. Filter the list by any tag you create."

    static let launchStagingMessage = "Preparing your experience..."

    /// Full description draft for App Store Connect (English).
    static let appStoreDescription = """
    Your personal event timeline — not just another generic countdown.

    Organize every date that matters with built-in categories or custom tags you create yourself. Tag a launch, a trip, a family milestone, or anything else — then filter your timeline by the labels that match how you actually think.

    • Custom tags alongside preset categories
    • Home overview with upcoming highlights and stats
    • Calendar month view with event markers
    • Search, filters, and flexible sorting
    • Daily inspiration quotes you can save and add yourself
    • Archive for past events with restore
    • Reminders and favorites — fully offline, no account required

    Clean white design with orange accents for what’s coming soon. Private data stays on your device.

    Perfect if you want one calm place for deadlines, celebrations, and everything in between — labeled your way.
    """
}

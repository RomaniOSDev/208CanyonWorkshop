//
//  LaunchSessionStore.swift
//  157Countdown
//

import Foundation

/// Launch-flow persistence (`LastUrl`, native shell flag).
final class LaunchSessionStore {
    static let shared = LaunchSessionStore()

    private let defaults = UserDefaults.standard
    private var lastURLKey: String { LaunchFlowSecrets.persistedNavigationURLKey }
    private var nativeShellKey: String { LaunchFlowSecrets.nativeShellPresentedKey }
    private var validatedWebEntryKey: String { LaunchFlowSecrets.validatedWebEntryKey }

    /// Persisted document URL after first successful WebView load (`LastUrl`).
    var savedLastURL: URL? {
        get {
            if let url = defaults.url(forKey: lastURLKey) {
                return url
            }
            if let legacy = defaults.string(forKey: lastURLKey),
               let url = URL(string: legacy) {
                defaults.set(url, forKey: lastURLKey)
                return url
            }
            return nil
        }
        set {
            defaults.set(newValue, forKey: lastURLKey)
        }
    }

    var hasShownNativeShell: Bool {
        get { defaults.bool(forKey: nativeShellKey) }
        set { defaults.set(newValue, forKey: nativeShellKey) }
    }

    var hasValidatedWebEntry: Bool {
        get { defaults.bool(forKey: validatedWebEntryKey) }
        set { defaults.set(newValue, forKey: validatedWebEntryKey) }
    }

    func markWebEntryValidated(url: URL) {
        savedLastURL = url
        hasValidatedWebEntry = true
    }

    func clearWebEntryState() {
        defaults.removeObject(forKey: lastURLKey)
        defaults.removeObject(forKey: validatedWebEntryKey)
    }

    func reconcileLegacyWebPersistence() {
        if savedLastURL != nil && !hasValidatedWebEntry {
            clearWebEntryState()
        }
    }

    private init() {}
}

import Foundation
import UIKit
import Combine
import StoreKit

enum ExternalLink: String {
    case privacyPolicy = "https://canyon208workshop.site/privacy/242"
    case terms = "https://canyon208workshop.site/terms/242"
}

final class SettingsViewModel: ObservableObject {
    @Published var showResetAlert = false
    @Published var backupText = ""
    @Published var showImportSheet = false
    @Published var showImportPicker = false
    @Published var showBackupShare = false
    @Published var importError = ""

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    func openPrivacyPolicy() {
        if let url = URL(string: ExternalLink.privacyPolicy.rawValue) {
            UIApplication.shared.open(url)
        }
    }

    func openTerms() {
        if let url = URL(string: ExternalLink.terms.rawValue) {
            UIApplication.shared.open(url)
        }
    }

    func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    func prepareBackup(from store: AppStorageStore) {
        backupText = store.exportBackupJSONString() ?? ""
        showBackupShare = !backupText.isEmpty
    }

    func importBackup(to store: AppStorageStore) {
        guard store.importBackupJSONString(backupText) else {
            importError = "Invalid backup JSON. Please check file content."
            FeedbackService.warning()
            return
        }
        importError = ""
        showImportSheet = false
        FeedbackService.actionSucceeded()
    }
}

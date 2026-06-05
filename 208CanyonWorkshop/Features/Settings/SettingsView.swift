import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppStorageStore
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 14) {
                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                AppSectionTitle(title: "Usage Stats", subtitle: "Your real-time activity overview")
                                statRow(title: "Entries", value: "\(store.entriesWritten)")
                                statRow(title: "Minutes Used", value: "\(store.totalMinutesUsed)")
                                statRow(title: "Current Streak", value: "\(store.streakDays) day(s)")
                                statRow(title: "Sessions", value: "\(store.totalSessionsCompleted)")
                            }
                        }

                        AppCard {
                            VStack(spacing: 2) {
                                settingsRow(title: "Rate Us", icon: "star.bubble") {
                                    viewModel.rateApp()
                                }
                                settingsRow(title: "Privacy", icon: "lock.doc") {
                                    viewModel.openPrivacyPolicy()
                                }
                                settingsRow(title: "Terms", icon: "doc.plaintext") {
                                    viewModel.openTerms()
                                }
                                settingsRow(title: "Export Backup", icon: "square.and.arrow.up") {
                                    viewModel.prepareBackup(from: store)
                                }
                                settingsRow(title: "Import Backup", icon: "square.and.arrow.down") {
                                    viewModel.showImportPicker = true
                                }
                                settingsRow(title: "Reset All Data", icon: "trash", isDestructive: true) {
                                    viewModel.showResetAlert = true
                                }
                            }
                        }

                        Text("Version \(viewModel.appVersion)")
                            .font(.footnote)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }
                    .padding(16)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showImportSheet) {
                importBackupSheet
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $viewModel.showImportPicker) {
                BackupImportPicker { text in
                    viewModel.backupText = text
                    viewModel.importBackup(to: store)
                } onError: { _ in
                    viewModel.showImportSheet = true
                }
            }
            .sheet(isPresented: $viewModel.showBackupShare) {
                BackupActivitySheet(text: viewModel.backupText)
            }
            .alert("Reset All Data?", isPresented: $viewModel.showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    store.resetAllData()
                }
            } message: {
                Text("This will permanently delete all local app data.")
            }
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color("AppTextSecondary"))
            Spacer()
            Text(value)
                .foregroundStyle(Color("AppTextPrimary"))
                .fontWeight(.semibold)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .appSurface(radius: 10)
    }

    private func settingsRow(title: String, icon: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            FeedbackService.tap()
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(isDestructive ? Color.red : Color("AppAccent"))
                    .frame(width: 22)
                Text(title)
                    .foregroundStyle(isDestructive ? Color.red : Color("AppTextPrimary"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .frame(minHeight: 44)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .appSurface(radius: 10)
        }
        .buttonStyle(.plain)
    }

    private var importBackupSheet: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Paste backup JSON")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextEditor(text: $viewModel.backupText)
                    .frame(minHeight: 220)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .background(Color("AppSurface"), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Color("AppTextPrimary"))

                if !viewModel.importError.isEmpty {
                    Text(viewModel.importError)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    viewModel.importBackup(to: store)
                } label: {
                    Text("Import Now")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color("AppPrimary"), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(16)
            .background(AppBackgroundView())
            .navigationTitle("Import Backup")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        FeedbackService.tap()
                        viewModel.showImportSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use File") {
                        FeedbackService.tap()
                        viewModel.showImportSheet = false
                        viewModel.showImportPicker = true
                    }
                }
            }
        }
    }
}

private struct BackupActivitySheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("melodytrack_backup_\(UUID().uuidString).json")
        try? text.data(using: .utf8)?.write(to: tempURL)
        return UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct BackupImportPicker: UIViewControllerRepresentable {
    let onPick: (String) -> Void
    let onError: (Error?) -> Void

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: BackupImportPicker

        init(parent: BackupImportPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                parent.onError(nil)
                return
            }
            let canAccess = url.startAccessingSecurityScopedResource()
            defer {
                if canAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            do {
                let data = try Data(contentsOf: url)
                guard let text = String(data: data, encoding: .utf8) else {
                    parent.onError(nil)
                    return
                }
                parent.onPick(text)
            } catch {
                parent.onError(error)
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(documentTypes: ["public.json"], in: .import)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}

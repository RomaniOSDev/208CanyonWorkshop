import Foundation
import SwiftUI
import Combine

final class AnnotationGalleryViewModel: ObservableObject {
    @Published var isEditorPresented = false
    @Published var isQuickNotePresented = false
    @Published var editingAnnotation: Annotation?
    @Published var titleInput = ""
    @Published var artistInput = ""
    @Published var noteInput = ""
    @Published var iconInput = "🎵"
    @Published var selectedMood = "None"
    @Published var selectedGenre = "None"
    @Published var selectedActivity = "None"

    @Published var quickTitleInput = ""
    @Published var quickTextInput = ""

    @Published var searchText = ""
    @Published var selectedTagFilter = "All Tags"
    @Published var filterFavoritesOnly = false
    @Published var filterLast7Days = false
    @Published var isBulkMode = false
    @Published var selectedIds: Set<String> = []

    @Published var validationError = ""
    @Published var shakeTrigger: CGFloat = 0
    @Published var showSuccessBadge = false
    @Published var deletedAnnotation: Annotation?
    @Published var showUndoSnackbar = false
    @Published var exportPayload = ""
    @Published var showShareSheet = false

    let moods = ["None", "Happy", "Calm", "Energetic", "Melancholic", "Focused"]
    let genres = ["None", "Pop", "Rock", "Jazz", "Electronic", "Classical", "Hip-Hop", "Indie"]
    let activities = ["None", "Workout", "Driving", "Study", "Relaxing", "Walking", "Travel"]

    func startCreating() {
        editingAnnotation = nil
        titleInput = ""
        artistInput = ""
        noteInput = ""
        iconInput = "🎵"
        selectedMood = "None"
        selectedGenre = "None"
        selectedActivity = "None"
        validationError = ""
        isEditorPresented = true
    }

    func startEditing(_ annotation: Annotation) {
        editingAnnotation = annotation
        titleInput = annotation.title
        artistInput = annotation.artist
        noteInput = annotation.text
        iconInput = annotation.icon
        selectedMood = tagValue(in: annotation.tags, prefix: "mood:")
        selectedGenre = tagValue(in: annotation.tags, prefix: "genre:")
        selectedActivity = tagValue(in: annotation.tags, prefix: "activity:")
        validationError = ""
        isEditorPresented = true
    }

    func save(using store: AppStorageStore) {
        let title = titleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let artist = artistInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = noteInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let icon = iconInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "🎵" : iconInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = buildTags()

        guard !title.isEmpty, !artist.isEmpty, !note.isEmpty else {
            validationError = "Please enter both title and note text."
            shakeTrigger += 1
            FeedbackService.warning()
            return
        }

        if let editingAnnotation {
            store.updateAnnotation(id: editingAnnotation.id, title: title, artist: artist, text: note, icon: icon, tags: tags)
        } else {
            store.addAnnotation(title: title, artist: artist, text: note, icon: icon, tags: tags)
        }

        FeedbackService.lightSave()
        FeedbackService.actionSucceeded()
        showSuccessBadge = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.showSuccessBadge = false
        }

        isEditorPresented = false
    }

    func saveQuickNote(using store: AppStorageStore) {
        let title = quickTitleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = quickTextInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !text.isEmpty else {
            validationError = "Please add title and short note."
            shakeTrigger += 1
            FeedbackService.warning()
            return
        }
        store.addAnnotation(title: title, artist: "Unknown Artist", text: text, icon: "⚡️", tags: [])
        quickTitleInput = ""
        quickTextInput = ""
        isQuickNotePresented = false
        FeedbackService.mediumSuccess()
    }

    func toggleBulkSelection(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }

    func stopBulkMode() {
        isBulkMode = false
        selectedIds.removeAll()
    }

    func delete(annotationId: String, store: AppStorageStore) {
        deletedAnnotation = store.deleteAnnotation(id: annotationId)
        showUndo()
    }

    func deleteBulk(store: AppStorageStore) {
        let deleted = store.deleteAnnotations(ids: selectedIds)
        deletedAnnotation = deleted.last
        selectedIds.removeAll()
        showUndo()
    }

    func undoDeletion(using store: AppStorageStore) {
        guard let deletedAnnotation else { return }
        store.restoreDeletedAnnotation(deletedAnnotation)
        self.deletedAnnotation = nil
        showUndoSnackbar = false
    }

    func filteredAnnotations(using store: AppStorageStore) -> [Annotation] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now

        return store.sortedAnnotations.filter { item in
            let matchesQuery = query.isEmpty || item.title.lowercased().contains(query) || item.text.lowercased().contains(query) || item.artist.lowercased().contains(query)
            let matchesFavorite = !filterFavoritesOnly || store.isNoteFavourite(annotationId: item.id)
            let matchesDate = !filterLast7Days || item.updatedAt >= sevenDaysAgo
            let matchesTag = selectedTagFilter == "All Tags" || item.tags.contains(selectedTagFilter)
            return matchesQuery && matchesFavorite && matchesDate && matchesTag
        }
    }

    func saveFiltersToStore(_ store: AppStorageStore) {
        store.galleryFilterFavoritesOnly = filterFavoritesOnly
        store.galleryFilterLast7Days = filterLast7Days
        store.registerGallerySearch(searchText)
    }

    func loadFilters(from store: AppStorageStore) {
        filterFavoritesOnly = store.galleryFilterFavoritesOnly
        filterLast7Days = store.galleryFilterLast7Days
    }

    func exportSelected(using store: AppStorageStore) {
        let items = store.sortedAnnotations.filter { selectedIds.contains($0.id) }
        guard !items.isEmpty else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items), let json = String(data: data, encoding: .utf8) else { return }
        exportPayload = json
        showShareSheet = true
    }

    func favouriteSelected(using store: AppStorageStore) {
        for id in selectedIds {
            if !store.isNoteFavourite(annotationId: id) {
                store.toggleNoteFavourite(annotationId: id)
            }
        }
        FeedbackService.actionSucceeded()
    }

    private func buildTags() -> [String] {
        var tags: [String] = []
        if selectedMood != "None" { tags.append("mood:\(selectedMood)") }
        if selectedGenre != "None" { tags.append("genre:\(selectedGenre)") }
        if selectedActivity != "None" { tags.append("activity:\(selectedActivity)") }
        return tags
    }

    private func tagValue(in tags: [String], prefix: String) -> String {
        guard let value = tags.first(where: { $0.hasPrefix(prefix) })?.replacingOccurrences(of: prefix, with: "") else {
            return "None"
        }
        return value
    }

    private func showUndo() {
        showUndoSnackbar = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            self?.showUndoSnackbar = false
            self?.deletedAnnotation = nil
        }
    }
}

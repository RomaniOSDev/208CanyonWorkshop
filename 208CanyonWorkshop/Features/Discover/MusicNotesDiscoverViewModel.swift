import Foundation
import Combine

struct DiscoverCollection: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let symbol: String
}

final class MusicNotesDiscoverViewModel: ObservableObject {
    @Published var selectedIds: Set<String> = []
    @Published var showSearchSheet = false
    @Published var query = ""
    @Published var showSuccessBadge = false

    let collections: [DiscoverCollection] = [
        DiscoverCollection(id: "curated_1", title: "Late Night Layers", description: "Ambient reflections for calm sessions.", symbol: "moon.stars.fill"),
        DiscoverCollection(id: "curated_2", title: "Acoustic Journal", description: "Warm notes for unplugged playlists.", symbol: "guitars.fill"),
        DiscoverCollection(id: "curated_3", title: "Focus Beats", description: "Clean rhythmic captions for work.", symbol: "waveform.path.ecg"),
        DiscoverCollection(id: "curated_4", title: "Roadtrip Notes", description: "Memory markers for long drives.", symbol: "car.fill"),
        DiscoverCollection(id: "curated_5", title: "Vinyl Moods", description: "Classic-inspired annotation prompts.", symbol: "opticaldisc.fill"),
        DiscoverCollection(id: "curated_6", title: "Indie Sparks", description: "Short hooks and lyrical highlights.", symbol: "sparkles")
    ]

    var filteredCollections: [DiscoverCollection] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return collections
        }
        return collections.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.description.localizedCaseInsensitiveContains(query)
        }
    }

    func toggleSelected(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }

    func saveSelected(using store: AppStorageStore) {
        let ids = Array(selectedIds)
        store.addFavourites(ids)
        selectedIds.removeAll()
        FeedbackService.softFavourite()
        FeedbackService.actionSucceeded()
        showSuccessBadge = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.showSuccessBadge = false
        }
    }
}

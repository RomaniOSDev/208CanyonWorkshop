import Foundation
import Combine

struct HomeQuickAction: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let imageName: String
    let tab: AppTab
}

struct HomeInspirationCard: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let imageName: String
}

final class HomeViewModel: ObservableObject {
    let quickActions: [HomeQuickAction] = [
        HomeQuickAction(
            id: "gallery",
            title: "My Annotations",
            subtitle: "Organize song notes",
            imageName: "HomeGalleryCard",
            tab: .gallery
        ),
        HomeQuickAction(
            id: "captions",
            title: "Music Captions",
            subtitle: "Write detailed thoughts",
            imageName: "HomeCaptionsCard",
            tab: .workbench
        ),
        HomeQuickAction(
            id: "discover",
            title: "Discover Notes",
            subtitle: "Find curated ideas",
            imageName: "HomeDiscoverCard",
            tab: .workbench
        )
    ]

    let inspirations: [HomeInspirationCard] = [
        HomeInspirationCard(
            title: "Capture the Mood",
            detail: "Tag each note with mood, genre, and activity.",
            imageName: "HomeGalleryCard"
        ),
        HomeInspirationCard(
            title: "Write While Listening",
            detail: "Use caption templates for faster annotation.",
            imageName: "HomeCaptionsCard"
        ),
        HomeInspirationCard(
            title: "Build Your Library",
            detail: "Favorite collections and revisit them anytime.",
            imageName: "HomeDiscoverCard"
        )
    ]

    func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }

    func recentAnnotations(from store: AppStorageStore) -> [Annotation] {
        Array(store.sortedAnnotations.prefix(5))
    }

    func unlockedCount(from store: AppStorageStore) -> Int {
        store.achievementsUnlocked.count
    }
}

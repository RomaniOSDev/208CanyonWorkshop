import Foundation
import Combine

final class OnboardingViewModel: ObservableObject {
    struct Page: Identifiable {
        let id = UUID()
        let headline: String
        let description: String
        let imageName: String
        let symbol: String
    }

    let pages: [Page] = [
        Page(
            headline: "Organize Your Music",
            description: "This app helps you manage and annotate your musical experiences.",
            imageName: "HomeGalleryCard",
            symbol: "music.note.list"
        ),
        Page(
            headline: "Capture Thoughts Instantly",
            description: "Tap to add detailed annotations to your favorite songs.",
            imageName: "HomeCaptionsCard",
            symbol: "pencil.and.scribble"
        ),
        Page(
            headline: "Start Annotating Now",
            description: "Begin by adding your first song note today.",
            imageName: "HomeHero",
            symbol: "sparkles"
        )
    ]
}

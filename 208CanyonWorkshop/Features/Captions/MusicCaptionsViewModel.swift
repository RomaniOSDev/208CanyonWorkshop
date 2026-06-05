import Foundation
import SwiftUI
import Combine

struct SongOption: Identifiable, Hashable {
    let id: String
    let title: String
    let artist: String
}

final class MusicCaptionsViewModel: ObservableObject {
    @Published var selectedSong: SongOption?
    @Published var captionText = ""
    @Published var captionDate = Date()
    @Published var showComposer = false
    @Published var showSuccessBadge = false
    @Published var validationError = ""
    @Published var shakeTrigger: CGFloat = 0
    @Published var editingCaption: Caption?

    let templates: [(title: String, body: String)] = [
        ("Lyrics insight", "Lyrics insight: "),
        ("Production note", "Production note: "),
        ("Emotion", "Emotion: ")
    ]

    let songs: [SongOption] = [
        SongOption(id: "song_01", title: "Night Skyline", artist: "Luna Drive"),
        SongOption(id: "song_02", title: "Ocean Strings", artist: "Aria Bloom"),
        SongOption(id: "song_03", title: "Solar Echo", artist: "Neon Harbor"),
        SongOption(id: "song_04", title: "Static Rain", artist: "Polar Tones"),
        SongOption(id: "song_05", title: "Quiet Tempo", artist: "Blue Sway")
    ]

    func openNewComposer() {
        editingCaption = nil
        selectedSong = songs.first
        captionText = ""
        captionDate = Date()
        validationError = ""
        showComposer = true
    }

    func openEditComposer(_ caption: Caption) {
        editingCaption = caption
        selectedSong = songs.first(where: { $0.id == caption.songId }) ?? SongOption(id: caption.songId, title: caption.songTitle, artist: caption.artist)
        captionText = caption.content
        captionDate = caption.timestamp
        validationError = ""
        showComposer = true
    }

    func save(using store: AppStorageStore) {
        guard let song = selectedSong else {
            validationError = "Please choose a song."
            shakeTrigger += 1
            FeedbackService.warning()
            return
        }

        let text = captionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            validationError = "Please add your caption."
            shakeTrigger += 1
            FeedbackService.warning()
            return
        }

        let caption = Caption(
            id: editingCaption?.id ?? UUID().uuidString,
            songId: song.id,
            songTitle: song.title,
            artist: song.artist,
            content: text,
            timestamp: captionDate
        )
        store.saveCaption(caption)
        FeedbackService.mediumSuccess()
        FeedbackService.actionSucceeded()
        showSuccessBadge = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.showSuccessBadge = false
        }
        showComposer = false
    }

    func applyTemplate(_ templateBody: String) {
        if captionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            captionText = templateBody
        } else {
            captionText += "\n\(templateBody)"
        }
        FeedbackService.tap()
    }
}

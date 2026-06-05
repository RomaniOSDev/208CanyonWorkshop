import Foundation
import SwiftUI
import Combine

struct Annotation: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var artist: String
    var text: String
    var icon: String
    var tags: [String]
    var isPinned: Bool
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        artist: String,
        text: String,
        icon: String,
        tags: [String] = [],
        isPinned: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.text = text
        self.icon = icon
        self.tags = tags
        self.isPinned = isPinned
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case text
        case icon
        case tags
        case isPinned
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decodeIfPresent(String.self, forKey: .artist) ?? "Unknown Artist"
        text = try container.decode(String.self, forKey: .text)
        icon = try container.decode(String.self, forKey: .icon)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}

struct Caption: Codable, Identifiable, Hashable {
    let id: String
    var songId: String
    var songTitle: String
    var artist: String
    var content: String
    var timestamp: Date

    init(
        id: String = UUID().uuidString,
        songId: String,
        songTitle: String,
        artist: String,
        content: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.songId = songId
        self.songTitle = songTitle
        self.artist = artist
        self.content = content
        self.timestamp = timestamp
    }
}

struct AchievementDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String

    static let all: [AchievementDefinition] = [
        AchievementDefinition(id: "first_note", title: "First Note", subtitle: "Added the first song note."),
        AchievementDefinition(id: "note_enthusiast", title: "Note Enthusiast", subtitle: "Added 10 song notes."),
        AchievementDefinition(id: "annotation_pro", title: "Annotation Pro", subtitle: "Wrote 50 entries in song notes."),
        AchievementDefinition(id: "daily_diligence", title: "Daily Diligence", subtitle: "Annotated daily for a week."),
        AchievementDefinition(id: "consistent_contributor", title: "Consistent Contributor", subtitle: "Maintained annotation streak for a month."),
        AchievementDefinition(id: "favorite_collector", title: "Favorite Collector", subtitle: "Marked at least one song note as a favorite."),
        AchievementDefinition(id: "top_curator", title: "Top Curator", subtitle: "Favourited ten unique notes."),
        AchievementDefinition(id: "avid_annotator", title: "Avid Annotator", subtitle: "Written entries every day for three consecutive months.")
    ]
}

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
}

struct AppBackup: Codable {
    let hasSeenOnboarding: Bool
    let totalSessionsCompleted: Int
    let totalMinutesUsed: Int
    let streakDays: Int
    let lastActivityDate: Date?
    let achievementsUnlocked: [String: Date]
    let annotations: [Annotation]
    let annotationCount: Int
    let captions: [Caption]
    let lastOpenedCaptionId: String?
    let recentlyEditedSongIds: [String]
    let favourites: [String]
    let lastVisitedDate: Date?
    let searchHistory: [String]
    let itemsAdded: Int
    let entriesWritten: Int
    let favouritesCount: Int
    let activityTimestamps: [Date]
    let gallerySearchHistory: [String]
    let galleryFilterFavoritesOnly: Bool
    let galleryFilterLast7Days: Bool
}

final class AppStorageStore: ObservableObject {
    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let totalSessionsCompleted = "totalSessionsCompleted"
        static let totalMinutesUsed = "totalMinutesUsed"
        static let streakDays = "streakDays"
        static let lastActivityDate = "lastActivityDate"
        static let achievementsUnlocked = "achievementsUnlocked"
        static let annotations = "annotations"
        static let annotationCount = "annotationCount"
        static let captions = "captions"
        static let lastOpenedCaptionId = "lastOpenedCaptionId"
        static let recentlyEditedSongIds = "recentlyEditedSongIds"
        static let favourites = "favourites"
        static let lastVisitedDate = "lastVisitedDate"
        static let searchHistory = "searchHistory"
        static let itemsAdded = "itemsAdded"
        static let entriesWritten = "entriesWritten"
        static let favouritesCount = "favouritesCount"
        static let activityTimestamps = "activityTimestamps"
        static let gallerySearchHistory = "gallerySearchHistory"
        static let galleryFilterFavoritesOnly = "galleryFilterFavoritesOnly"
        static let galleryFilterLast7Days = "galleryFilterLast7Days"
    }

    @Published var hasSeenOnboarding = false { didSet { save(Keys.hasSeenOnboarding, value: hasSeenOnboarding) } }
    @Published var totalSessionsCompleted = 0 { didSet { save(Keys.totalSessionsCompleted, value: totalSessionsCompleted) } }
    @Published var totalMinutesUsed = 0 { didSet { save(Keys.totalMinutesUsed, value: totalMinutesUsed) } }
    @Published var streakDays = 0 { didSet { save(Keys.streakDays, value: streakDays) } }
    @Published var lastActivityDate: Date? { didSet { saveDate(Keys.lastActivityDate, value: lastActivityDate) } }
    @Published var achievementsUnlocked: [String: Date] = [:] { didSet { saveCodable(Keys.achievementsUnlocked, value: achievementsUnlocked) } }

    @Published var annotations: [Annotation] = [] { didSet { saveCodable(Keys.annotations, value: annotations) } }
    @Published var annotationCount = 0 { didSet { save(Keys.annotationCount, value: annotationCount) } }

    @Published var captions: [Caption] = [] { didSet { saveCodable(Keys.captions, value: captions) } }
    @Published var lastOpenedCaptionId: String? { didSet { saveOptionalString(Keys.lastOpenedCaptionId, value: lastOpenedCaptionId) } }
    @Published var recentlyEditedSongIds: [String] = [] { didSet { saveCodable(Keys.recentlyEditedSongIds, value: recentlyEditedSongIds) } }

    @Published var favourites: [String] = [] { didSet { saveCodable(Keys.favourites, value: favourites) } }
    @Published var lastVisitedDate: Date? { didSet { saveDate(Keys.lastVisitedDate, value: lastVisitedDate) } }
    @Published var searchHistory: [String] = [] { didSet { saveCodable(Keys.searchHistory, value: searchHistory) } }

    @Published var itemsAdded = 0 { didSet { save(Keys.itemsAdded, value: itemsAdded) } }
    @Published var entriesWritten = 0 { didSet { save(Keys.entriesWritten, value: entriesWritten) } }
    @Published var favouritesCount = 0 { didSet { save(Keys.favouritesCount, value: favouritesCount) } }
    @Published var activityTimestamps: [Date] = [] { didSet { saveCodable(Keys.activityTimestamps, value: activityTimestamps) } }
    @Published var gallerySearchHistory: [String] = [] { didSet { saveCodable(Keys.gallerySearchHistory, value: gallerySearchHistory) } }
    @Published var galleryFilterFavoritesOnly = false { didSet { save(Keys.galleryFilterFavoritesOnly, value: galleryFilterFavoritesOnly) } }
    @Published var galleryFilterLast7Days = false { didSet { save(Keys.galleryFilterLast7Days, value: galleryFilterLast7Days) } }

    @Published var achievementBannerQueue: [AchievementDefinition] = []

    private let defaults: UserDefaults
    private var isRestoring = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        restoreState()
    }

    var sortedAnnotations: [Annotation] {
        annotations.sorted {
            if $0.isPinned != $1.isPinned {
                return $0.isPinned && !$1.isPinned
            }
            return $0.updatedAt > $1.updatedAt
        }
    }

    var topTags: [(String, Int)] {
        let counts = annotations.flatMap(\.tags).reduce(into: [String: Int]()) { partialResult, tag in
            partialResult[tag, default: 0] += 1
        }
        return counts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }
                return lhs.value > rhs.value
            }
            .prefix(5)
            .map { ($0.key, $0.value) }
    }

    var currentMonthInsights: (artist: String, activeDayTime: String, averageNotesPerSession: String) {
        let calendar = Calendar.current
        let now = Date()
        let monthItems = annotations.filter { calendar.isDate($0.updatedAt, equalTo: now, toGranularity: .month) }
        let monthCaptions = captions.filter { calendar.isDate($0.timestamp, equalTo: now, toGranularity: .month) }
        let monthSessions = activityTimestamps.filter { calendar.isDate($0, equalTo: now, toGranularity: .month) }

        let artists = monthItems.map(\.artist) + monthCaptions.map(\.artist)
        let artistWinner = mostFrequent(in: artists) ?? "No data yet"

        let weekdayHour = monthSessions.map { date -> String in
            let weekday = calendar.component(.weekday, from: date)
            let hour = calendar.component(.hour, from: date)
            return "\(weekday)-\(timeBucket(for: hour))"
        }
        let activeWinner = mostFrequent(in: weekdayHour).map(prettyActiveSlot(_:)) ?? "No data yet"

        let totalEntries = monthItems.count + monthCaptions.count
        let average = monthSessions.isEmpty ? 0 : Double(totalEntries) / Double(monthSessions.count)
        let formattedAverage = String(format: "%.1f notes/session", average)

        return (artistWinner, activeWinner, monthSessions.isEmpty ? "No data yet" : formattedAverage)
    }

    func addAnnotation(title: String, artist: String, text: String, icon: String, tags: [String]) {
        let annotation = Annotation(title: title, artist: artist, text: text, icon: icon, tags: tags, updatedAt: Date())
        annotations.append(annotation)
        annotationCount = annotations.count
        itemsAdded += 1
        entriesWritten += 1
        registerMeaningfulAction(minutes: 1)
    }

    func updateAnnotation(id: String, title: String, artist: String, text: String, icon: String, tags: [String]) {
        guard let index = annotations.firstIndex(where: { $0.id == id }) else { return }
        annotations[index].title = title
        annotations[index].artist = artist
        annotations[index].text = text
        annotations[index].icon = icon
        annotations[index].tags = tags
        annotations[index].updatedAt = Date()
        entriesWritten += 1
        registerMeaningfulAction(minutes: 1)
    }

    @discardableResult
    func deleteAnnotation(id: String) -> Annotation? {
        guard let item = annotations.first(where: { $0.id == id }) else { return nil }
        annotations.removeAll(where: { $0.id == id })
        favourites.removeAll(where: { $0 == noteFavouriteId(annotationId: id) })
        annotationCount = annotations.count
        favouritesCount = favourites.count
        return item
    }

    func restoreDeletedAnnotation(_ annotation: Annotation) {
        annotations.append(annotation)
        annotationCount = annotations.count
    }

    func toggleAnnotationPinned(annotationId: String) {
        guard let index = annotations.firstIndex(where: { $0.id == annotationId }) else { return }
        annotations[index].isPinned.toggle()
        annotations[index].updatedAt = Date()
        registerMeaningfulAction(minutes: 1)
    }

    func deleteAnnotations(ids: Set<String>) -> [Annotation] {
        let deleted = annotations.filter { ids.contains($0.id) }
        annotations.removeAll { ids.contains($0.id) }
        favourites.removeAll { favorite in
            ids.contains { noteFavouriteId(annotationId: $0) == favorite }
        }
        annotationCount = annotations.count
        favouritesCount = favourites.count
        return deleted
    }

    func saveCaption(_ caption: Caption) {
        if let index = captions.firstIndex(where: { $0.id == caption.id }) {
            captions[index] = caption
        } else {
            captions.insert(caption, at: 0)
        }

        lastOpenedCaptionId = caption.id
        entriesWritten += 1
        markSongAsRecentlyEdited(caption.songId)
        registerMeaningfulAction(minutes: 2)
    }

    func deleteCaption(id: String) {
        captions.removeAll(where: { $0.id == id })
    }

    func toggleFavourite(collectionId: String) {
        if favourites.contains(collectionId) {
            favourites.removeAll(where: { $0 == collectionId })
        } else {
            favourites.append(collectionId)
        }
        favourites = Array(Set(favourites)).sorted()
        favouritesCount = favourites.count
        registerMeaningfulAction(minutes: 1)
    }

    func toggleNoteFavourite(annotationId: String) {
        let favouriteId = noteFavouriteId(annotationId: annotationId)
        toggleFavourite(collectionId: favouriteId)
    }

    func isNoteFavourite(annotationId: String) -> Bool {
        favourites.contains(noteFavouriteId(annotationId: annotationId))
    }

    func addFavourites(_ ids: [String]) {
        guard !ids.isEmpty else { return }
        favourites = Array(Set(favourites + ids)).sorted()
        favouritesCount = favourites.count
        registerMeaningfulAction(minutes: 1)
    }

    func registerSearch(_ query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var updated = [query]
        for item in searchHistory where item.caseInsensitiveCompare(query) != .orderedSame {
            updated.append(item)
        }
        searchHistory = Array(updated.prefix(10))
    }

    func markDiscoverVisited() {
        lastVisitedDate = Date()
    }

    func popAchievementBanner() {
        guard !achievementBannerQueue.isEmpty else { return }
        achievementBannerQueue.removeFirst()
    }

    func registerMeaningfulAction(minutes: Int) {
        totalSessionsCompleted += 1
        totalMinutesUsed += max(minutes, 1)
        activityTimestamps.append(Date())
        activityTimestamps = Array(activityTimestamps.suffix(1200))
        updateStreak()
        evaluateAchievements()
    }

    func registerGallerySearch(_ query: String) {
        let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        var history = [value]
        for item in gallerySearchHistory where item.caseInsensitiveCompare(value) != .orderedSame {
            history.append(item)
        }
        gallerySearchHistory = Array(history.prefix(10))
    }

    func exportBackupJSONString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let backup = AppBackup(
            hasSeenOnboarding: hasSeenOnboarding,
            totalSessionsCompleted: totalSessionsCompleted,
            totalMinutesUsed: totalMinutesUsed,
            streakDays: streakDays,
            lastActivityDate: lastActivityDate,
            achievementsUnlocked: achievementsUnlocked,
            annotations: annotations,
            annotationCount: annotationCount,
            captions: captions,
            lastOpenedCaptionId: lastOpenedCaptionId,
            recentlyEditedSongIds: recentlyEditedSongIds,
            favourites: favourites,
            lastVisitedDate: lastVisitedDate,
            searchHistory: searchHistory,
            itemsAdded: itemsAdded,
            entriesWritten: entriesWritten,
            favouritesCount: favouritesCount,
            activityTimestamps: activityTimestamps,
            gallerySearchHistory: gallerySearchHistory,
            galleryFilterFavoritesOnly: galleryFilterFavoritesOnly,
            galleryFilterLast7Days: galleryFilterLast7Days
        )

        guard let data = try? encoder.encode(backup) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func importBackupJSONString(_ json: String) -> Bool {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard
            let data = json.data(using: .utf8),
            let backup = try? decoder.decode(AppBackup.self, from: data)
        else {
            return false
        }

        isRestoring = true

        hasSeenOnboarding = backup.hasSeenOnboarding
        totalSessionsCompleted = backup.totalSessionsCompleted
        totalMinutesUsed = backup.totalMinutesUsed
        streakDays = backup.streakDays
        lastActivityDate = backup.lastActivityDate
        achievementsUnlocked = backup.achievementsUnlocked
        annotations = backup.annotations
        annotationCount = backup.annotationCount
        captions = backup.captions
        lastOpenedCaptionId = backup.lastOpenedCaptionId
        recentlyEditedSongIds = backup.recentlyEditedSongIds
        favourites = backup.favourites
        lastVisitedDate = backup.lastVisitedDate
        searchHistory = backup.searchHistory
        itemsAdded = backup.itemsAdded
        entriesWritten = backup.entriesWritten
        favouritesCount = backup.favouritesCount
        activityTimestamps = backup.activityTimestamps
        gallerySearchHistory = backup.gallerySearchHistory
        galleryFilterFavoritesOnly = backup.galleryFilterFavoritesOnly
        galleryFilterLast7Days = backup.galleryFilterLast7Days

        isRestoring = false
        persistAll()
        evaluateAchievements()
        return true
    }

    func resetAllData() {
        let allKeys = [
            Keys.hasSeenOnboarding,
            Keys.totalSessionsCompleted,
            Keys.totalMinutesUsed,
            Keys.streakDays,
            Keys.lastActivityDate,
            Keys.achievementsUnlocked,
            Keys.annotations,
            Keys.annotationCount,
            Keys.captions,
            Keys.lastOpenedCaptionId,
            Keys.recentlyEditedSongIds,
            Keys.favourites,
            Keys.lastVisitedDate,
            Keys.searchHistory,
            Keys.itemsAdded,
            Keys.entriesWritten,
            Keys.favouritesCount,
            Keys.activityTimestamps,
            Keys.gallerySearchHistory,
            Keys.galleryFilterFavoritesOnly,
            Keys.galleryFilterLast7Days
        ]

        allKeys.forEach { defaults.removeObject(forKey: $0) }
        restoreState()
        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    private func restoreState() {
        isRestoring = true
        defer { isRestoring = false }

        hasSeenOnboarding = defaults.object(forKey: Keys.hasSeenOnboarding) as? Bool ?? false
        totalSessionsCompleted = defaults.object(forKey: Keys.totalSessionsCompleted) as? Int ?? 0
        totalMinutesUsed = defaults.object(forKey: Keys.totalMinutesUsed) as? Int ?? 0
        streakDays = defaults.object(forKey: Keys.streakDays) as? Int ?? 0
        lastActivityDate = defaults.object(forKey: Keys.lastActivityDate) as? Date

        achievementsUnlocked = loadCodable([String: Date].self, key: Keys.achievementsUnlocked) ?? [:]
        annotations = loadCodable([Annotation].self, key: Keys.annotations) ?? []
        annotationCount = defaults.object(forKey: Keys.annotationCount) as? Int ?? annotations.count
        captions = loadCodable([Caption].self, key: Keys.captions) ?? []
        lastOpenedCaptionId = defaults.string(forKey: Keys.lastOpenedCaptionId)
        recentlyEditedSongIds = loadCodable([String].self, key: Keys.recentlyEditedSongIds) ?? []
        favourites = loadCodable([String].self, key: Keys.favourites) ?? []
        lastVisitedDate = defaults.object(forKey: Keys.lastVisitedDate) as? Date
        searchHistory = loadCodable([String].self, key: Keys.searchHistory) ?? []
        itemsAdded = defaults.object(forKey: Keys.itemsAdded) as? Int ?? annotationCount
        entriesWritten = defaults.object(forKey: Keys.entriesWritten) as? Int ?? (annotationCount + captions.count)
        favouritesCount = defaults.object(forKey: Keys.favouritesCount) as? Int ?? favourites.count
        activityTimestamps = loadCodable([Date].self, key: Keys.activityTimestamps) ?? []
        gallerySearchHistory = loadCodable([String].self, key: Keys.gallerySearchHistory) ?? []
        galleryFilterFavoritesOnly = defaults.object(forKey: Keys.galleryFilterFavoritesOnly) as? Bool ?? false
        galleryFilterLast7Days = defaults.object(forKey: Keys.galleryFilterLast7Days) as? Bool ?? false
    }

    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = lastActivityDate.map { calendar.startOfDay(for: $0) }

        switch lastDay {
        case nil:
            streakDays = 1
        case .some(let day) where calendar.isDate(day, inSameDayAs: today):
            break
        case .some(let day):
            let delta = calendar.dateComponents([.day], from: day, to: today).day ?? 0
            streakDays = delta == 1 ? streakDays + 1 : 1
        }

        lastActivityDate = today
    }

    private func evaluateAchievements() {
        for achievement in AchievementDefinition.all {
            guard achievementsUnlocked[achievement.id] == nil else { continue }
            if isConditionMet(for: achievement.id) {
                achievementsUnlocked[achievement.id] = Date()
                achievementBannerQueue.append(achievement)
                FeedbackService.achievementUnlocked()
            }
        }
    }

    private func isConditionMet(for id: String) -> Bool {
        switch id {
        case "first_note":
            return itemsAdded >= 1
        case "note_enthusiast":
            return itemsAdded >= 10
        case "annotation_pro":
            return entriesWritten >= 50
        case "daily_diligence":
            return streakDays >= 7
        case "consistent_contributor":
            return streakDays >= 30
        case "favorite_collector":
            return favouritesCount >= 1
        case "top_curator":
            return favouritesCount >= 10
        case "avid_annotator":
            return streakDays >= 90
        default:
            return false
        }
    }

    private func markSongAsRecentlyEdited(_ songId: String) {
        var updated = [songId]
        for id in recentlyEditedSongIds where id != songId {
            updated.append(id)
        }
        recentlyEditedSongIds = Array(updated.prefix(20))
    }

    private func noteFavouriteId(annotationId: String) -> String {
        "note_\(annotationId)"
    }

    private func mostFrequent(in values: [String]) -> String? {
        let counts = values.reduce(into: [String: Int]()) { result, value in
            guard !value.isEmpty else { return }
            result[value, default: 0] += 1
        }
        return counts.max { $0.value < $1.value }?.key
    }

    private func timeBucket(for hour: Int) -> String {
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<22: return "Evening"
        default: return "Night"
        }
    }

    private func prettyActiveSlot(_ raw: String) -> String {
        let chunks = raw.split(separator: "-")
        guard chunks.count == 2, let weekday = Int(chunks[0]) else { return raw }
        let name = Calendar.current.weekdaySymbols[max(0, min(weekday - 1, 6))]
        return "\(name), \(chunks[1])"
    }

    private func persistAll() {
        save(Keys.hasSeenOnboarding, value: hasSeenOnboarding)
        save(Keys.totalSessionsCompleted, value: totalSessionsCompleted)
        save(Keys.totalMinutesUsed, value: totalMinutesUsed)
        save(Keys.streakDays, value: streakDays)
        saveDate(Keys.lastActivityDate, value: lastActivityDate)
        saveCodable(Keys.achievementsUnlocked, value: achievementsUnlocked)
        saveCodable(Keys.annotations, value: annotations)
        save(Keys.annotationCount, value: annotationCount)
        saveCodable(Keys.captions, value: captions)
        saveOptionalString(Keys.lastOpenedCaptionId, value: lastOpenedCaptionId)
        saveCodable(Keys.recentlyEditedSongIds, value: recentlyEditedSongIds)
        saveCodable(Keys.favourites, value: favourites)
        saveDate(Keys.lastVisitedDate, value: lastVisitedDate)
        saveCodable(Keys.searchHistory, value: searchHistory)
        save(Keys.itemsAdded, value: itemsAdded)
        save(Keys.entriesWritten, value: entriesWritten)
        save(Keys.favouritesCount, value: favouritesCount)
        saveCodable(Keys.activityTimestamps, value: activityTimestamps)
        saveCodable(Keys.gallerySearchHistory, value: gallerySearchHistory)
        save(Keys.galleryFilterFavoritesOnly, value: galleryFilterFavoritesOnly)
        save(Keys.galleryFilterLast7Days, value: galleryFilterLast7Days)
    }

    private func save(_ key: String, value: Int) {
        guard !isRestoring else { return }
        defaults.set(value, forKey: key)
    }

    private func save(_ key: String, value: Bool) {
        guard !isRestoring else { return }
        defaults.set(value, forKey: key)
    }

    private func saveDate(_ key: String, value: Date?) {
        guard !isRestoring else { return }
        defaults.set(value, forKey: key)
    }

    private func saveOptionalString(_ key: String, value: String?) {
        guard !isRestoring else { return }
        defaults.set(value, forKey: key)
    }

    private func saveCodable<T: Codable>(_ key: String, value: T) {
        guard !isRestoring else { return }
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private func loadCodable<T: Codable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

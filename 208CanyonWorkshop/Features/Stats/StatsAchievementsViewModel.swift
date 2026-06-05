import Foundation
import Combine

final class StatsAchievementsViewModel: ObservableObject {
    func isUnlocked(_ achievement: AchievementDefinition, store: AppStorageStore) -> Bool {
        store.achievementsUnlocked[achievement.id] != nil
    }
}

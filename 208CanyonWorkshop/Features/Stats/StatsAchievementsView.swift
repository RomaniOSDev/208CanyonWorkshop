import SwiftUI

struct StatsAchievementsView: View {
    @EnvironmentObject private var store: AppStorageStore
    @StateObject private var viewModel = StatsAchievementsViewModel()

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 16) {
                        summaryCard
                        topTagsCard
                        monthlyInsightsCard
                        heatmapCard

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(AchievementDefinition.all) { achievement in
                                achievementCard(achievement)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var summaryCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Summary")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                Text("Sessions: \(store.totalSessionsCompleted)")
                    .foregroundStyle(Color("AppTextSecondary"))
                Text("Minutes Used: \(store.totalMinutesUsed)")
                    .foregroundStyle(Color("AppTextSecondary"))
                Text("Current Streak: \(store.streakDays) day(s)")
                    .foregroundStyle(Color("AppTextSecondary"))
                Text("Unlocked: \(store.achievementsUnlocked.count)/8")
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var topTagsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Top Tags")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                if store.topTags.isEmpty {
                    Text("No tags yet")
                        .foregroundStyle(Color("AppTextSecondary"))
                } else {
                    ForEach(store.topTags, id: \.0) { item in
                        HStack {
                            Text(item.0.replacingOccurrences(of: "mood:", with: "Mood: ").replacingOccurrences(of: "genre:", with: "Genre: ").replacingOccurrences(of: "activity:", with: "Activity: "))
                                .foregroundStyle(Color("AppTextSecondary"))
                            Spacer()
                            Text("\(item.1)")
                                .foregroundStyle(Color("AppAccent"))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var monthlyInsightsCard: some View {
        let insights = store.currentMonthInsights
        return AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Monthly Insights")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                Text("Most annotated artist: \(insights.artist)")
                    .foregroundStyle(Color("AppTextSecondary"))
                Text("Most active day/time: \(insights.activeDayTime)")
                    .foregroundStyle(Color("AppTextSecondary"))
                Text("Average notes per session: \(insights.averageNotesPerSession)")
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var heatmapCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Calendar Heatmap")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                HeatmapGridView(activityDates: store.activityTimestamps)
                Text("Darker cells indicate more activity.")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func achievementCard(_ achievement: AchievementDefinition) -> some View {
        let unlocked = viewModel.isUnlocked(achievement, store: store)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: unlocked ? "star.fill" : "star")
                    .foregroundStyle(unlocked ? Color("AppAccent") : Color("AppTextSecondary"))
                Spacer()
            }
            Text(achievement.title)
                .font(.subheadline.bold())
                .foregroundStyle(Color("AppTextPrimary"))
            Text(achievement.subtitle)
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    unlocked
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [Color("AppPrimary").opacity(0.42), Color("AppAccent").opacity(0.28)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    : AnyShapeStyle(AppDesign.cardGradient)
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(unlocked ? Color("AppAccent").opacity(0.55) : Color("AppTextSecondary").opacity(0.2), lineWidth: 1)
        )
        .modifier(AppShadowModifier(enabled: unlocked, radius: 5, y: 2))
    }
}

private struct HeatmapGridView: View {
    let activityDates: [Date]

    private let rows = 7
    private let columns = 16

    var body: some View {
        let values = makeHeatmapValues()
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<columns, id: \.self) { column in
                        let index = (column * rows) + row
                        let value = index < values.count ? values[index] : 0
                        RoundedRectangle(cornerRadius: 3)
                            .fill(cellColor(for: value))
                            .frame(width: 14, height: 14)
                    }
                }
            }
        }
    }

    private func makeHeatmapValues() -> [Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -((rows * columns) - 1), to: today) ?? today

        var day = start
        var output: [Int] = []
        while day <= today {
            let count = activityDates.filter { calendar.isDate($0, inSameDayAs: day) }.count
            output.append(count)
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? today
        }
        return output
    }

    private func cellColor(for value: Int) -> Color {
        switch value {
        case 0: return Color("AppBackground")
        case 1: return Color("AppPrimary").opacity(0.45)
        case 2: return Color("AppPrimary").opacity(0.65)
        case 3: return Color("AppAccent").opacity(0.85)
        default: return Color("AppAccent")
        }
    }
}

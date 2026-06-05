import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AppStorageStore
    @StateObject private var viewModel = HomeViewModel()
    @Binding var selectedTab: AppTab

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 16) {
                        heroWidget
                        statsWidget
                        quickActionsWidget
                        recentNotesWidget
                        insightsWidget
                        inspirationWidget
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 110)
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var heroWidget: some View {
        ZStack(alignment: .bottomLeading) {
            Image("HomeHero")
                .resizable()
                .scaledToFill()
                .frame(height: 190)
                .clipped()

            LinearGradient(
                colors: [Color("AppBackground").opacity(0.1), Color("AppBackground").opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.greeting())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppAccent"))
                Text("Your Music Journal")
                    .font(.title2.bold())
                    .foregroundStyle(Color("AppTextPrimary"))
                Text("Capture notes, captions, and inspiration in one place.")
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(2)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppDesign.accentStroke, lineWidth: 1)
        )
        .compositingGroup()
        .shadow(color: Color("AppBackground").opacity(0.4), radius: 8, x: 0, y: 4)
    }

    private var statsWidget: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                AppSectionTitle(title: "Today at a Glance", subtitle: "Live counters from your activity")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    statTile(title: "Notes", value: "\(store.annotations.count)", icon: "music.note.list")
                    statTile(title: "Captions", value: "\(store.captions.count)", icon: "text.quote")
                    statTile(title: "Streak", value: "\(store.streakDays)d", icon: "flame.fill")
                    statTile(title: "Badges", value: "\(viewModel.unlockedCount(from: store))/8", icon: "star.fill")
                }
            }
        }
    }

    private func statTile(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(Color("AppAccent"))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                Text(value)
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
            }
            Spacer()
        }
        .padding(10)
        .appSurface(radius: 12)
    }

    private var quickActionsWidget: some View {
        VStack(alignment: .leading, spacing: 10) {
            AppSectionTitle(title: "Quick Actions", subtitle: "Jump into your main tools")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.quickActions) { action in
                        Button {
                            FeedbackService.tap()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = action.tab
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(action.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 96)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                Text(action.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .lineLimit(1)
                                Text(action.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                    .lineLimit(2)
                            }
                            .frame(width: 150)
                            .padding(10)
                            .appElevatedCard(radius: 14)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var recentNotesWidget: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    AppSectionTitle(title: "Recent Notes", subtitle: "Your latest annotations")
                    Spacer()
                    Button("See All") {
                        FeedbackService.tap()
                        selectedTab = .gallery
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Color("AppAccent"))
                }

                let recent = viewModel.recentAnnotations(from: store)
                if recent.isEmpty {
                    Text("No notes yet. Start in Gallery.")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                } else {
                    ForEach(recent) { note in
                        HStack(spacing: 10) {
                            Text(note.icon)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(note.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .lineLimit(1)
                                Text(note.text)
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                    .lineLimit(1)
                            }
                            Spacer()
                            if note.isPinned {
                                Image(systemName: "pin.fill")
                                    .font(.caption2)
                                    .foregroundStyle(Color("AppAccent"))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private var insightsWidget: some View {
        let insights = store.currentMonthInsights
        return AppCard {
            VStack(alignment: .leading, spacing: 10) {
                AppSectionTitle(title: "Monthly Insights", subtitle: "Patterns from this month")
                insightRow(icon: "person.wave.2", text: "Top artist: \(insights.artist)")
                insightRow(icon: "clock", text: "Active slot: \(insights.activeDayTime)")
                insightRow(icon: "chart.line.uptrend.xyaxis", text: insights.averageNotesPerSession)
            }
        }
    }

    private func insightRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color("AppAccent"))
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
            Spacer()
        }
    }

    private var inspirationWidget: some View {
        VStack(alignment: .leading, spacing: 10) {
            AppSectionTitle(title: "Inspiration", subtitle: "Tips to improve your annotation flow")

            ForEach(viewModel.inspirations) { card in
                HStack(spacing: 12) {
                    Image(card.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text(card.detail)
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(12)
                .appElevatedCard(radius: 14)
            }
        }
    }
}

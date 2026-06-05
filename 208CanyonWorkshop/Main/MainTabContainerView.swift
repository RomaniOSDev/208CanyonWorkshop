import SwiftUI

struct MainTabContainerView: View {
    @EnvironmentObject private var store: AppStorageStore
    @State private var selectedTab: AppTab = .home
    @State private var pressedTab: AppTab?

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(selectedTab: $selectedTab)
                case .gallery:
                    AnnotationGalleryView()
                case .workbench:
                    CaptionsDiscoverWorkbenchView()
                case .stats:
                    StatsAchievementsView()
                case .settings:
                    SettingsView()
                }
            }
            .environmentObject(store)

            customTabBar
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 10) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                Button {
                    FeedbackService.tap()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: .semibold))
                        Text(tab.title)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(selectedTab == tab ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                selectedTab == tab
                                ? AnyShapeStyle(AppDesign.primaryGradient)
                                : AnyShapeStyle(AppDesign.cardGradient)
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color("AppAccent").opacity(selectedTab == tab ? 0.5 : 0.18), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .scaleEffect(pressedTab == tab ? 0.95 : 1)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            pressedTab = tab
                        }
                        .onEnded { _ in
                            pressedTab = nil
                        }
                )
            }
        }
        .padding(10)
        .background(AppDesign.cardGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppDesign.accentStroke, lineWidth: 1)
        )
        .compositingGroup()
        .shadow(color: Color("AppBackground").opacity(0.45), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }
}

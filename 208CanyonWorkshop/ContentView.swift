//
//  ContentView.swift
//  208CanyonWorkshop
//
//  Created by Roman on 6/5/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppStorageStore()
    @State private var activeBanner: AchievementDefinition?
    @State private var bannerVisible = false

    var body: some View {
        ZStack(alignment: .top) {
            if store.hasSeenOnboarding {
                MainTabContainerView()
                    .environmentObject(store)
            } else {
                OnboardingView {
                    FeedbackService.actionSucceeded()
                    store.hasSeenOnboarding = true
                    store.registerMeaningfulAction(minutes: 1)
                }
            }

            if let activeBanner, bannerVisible {
                AchievementBannerView(achievement: activeBanner)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: bannerVisible)
        .onReceive(store.$achievementBannerQueue) { queue in
            guard activeBanner == nil, let next = queue.first else { return }
            activeBanner = next
            bannerVisible = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    bannerVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    store.popAchievementBanner()
                    activeBanner = nil
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Color("AppPrimary"))
    }
}

#Preview {
    ContentView()
}

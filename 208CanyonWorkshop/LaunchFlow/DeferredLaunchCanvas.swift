//
//  DeferredLaunchCanvas.swift
//  157Countdown
//

import SwiftUI

struct DeferredLaunchCanvas: View {
    @ObservedObject var state: LaunchStagingState

    var body: some View {
        ZStack {
            Image(.start)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.35),
                    Color.black.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ProgressView(value: max(0.05, state.progress))
                    .progressViewStyle(.linear)
                    .tint(.white)
                    .frame(width: 200)

                Text(state.statusMessage)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 32)

                Spacer()
                    .frame(height: 80)
            }
        }
    }
}

#if DEBUG
#Preview {
    DeferredLaunchCanvas(state: LaunchStagingState())
}
#endif

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var currentIndex = 0
    @State private var showIllustration = false
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 20) {
                headerBar

                TabView(selection: $currentIndex) {
                    ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                        pageCard(page: page, index: index)
                            .tag(index)
                            .padding(.horizontal, 18)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentIndex)

                pageIndicator

                actionButton

                Spacer(minLength: 24)
            }
            .padding(.top, 12)
        }
        .onAppear {
            showIllustration = true
        }
        .onChange(of: currentIndex) { _ in
            showIllustration = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showIllustration = true
                }
            }
        }
    }

    private var headerBar: some View {
        HStack {
            Image(systemName: "waveform")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color("AppAccent"))
            Text("Getting Started")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("AppTextPrimary"))
            Spacer()
            Text("Step \(currentIndex + 1)/\(viewModel.pages.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AppTextSecondary"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .appSurface(radius: 10)
        }
        .padding(.horizontal, 20)
    }

    private func pageCard(page: OnboardingViewModel.Page, index: Int) -> some View {
        AppCard {
            VStack(spacing: 18) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppDesign.cardGradient)

                    Image(page.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 176)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)

                    LinearGradient(
                        colors: [Color("AppBackground").opacity(0.05), Color("AppBackground").opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    HStack(spacing: 8) {
                        Image(systemName: page.symbol)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .padding(8)
                            .background(AppDesign.primaryGradient, in: Circle())
                        Text("Feature Preview")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                    .padding(12)
                }
                .frame(height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppDesign.accentStroke, lineWidth: 1)
                )
                .opacity(showIllustration && currentIndex == index ? 1 : 0)
                .scaleEffect(showIllustration && currentIndex == index ? 1 : 0.92)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showIllustration)

                VStack(spacing: 10) {
                    Text(page.headline)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .padding(.horizontal, 8)

                    Text(page.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .padding(.horizontal, 10)
                }
                .opacity(showIllustration && currentIndex == index ? 1 : 0.6)
                .offset(y: showIllustration && currentIndex == index ? 0 : 8)
                .animation(.easeInOut(duration: 0.3), value: showIllustration)
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.pages.count, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(
                        index == currentIndex
                        ? AnyShapeStyle(AppDesign.primaryGradient)
                        : AnyShapeStyle(Color("AppSurface"))
                    )
                    .frame(width: index == currentIndex ? 22 : 8, height: 8)
                    .overlay {
                        if index != currentIndex {
                            Capsule()
                                .stroke(Color("AppAccent").opacity(0.25), lineWidth: 1)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
            }
        }
    }

    private var actionButton: some View {
        Button {
            FeedbackService.tap()
            if currentIndex < viewModel.pages.count - 1 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentIndex += 1
                }
            } else {
                onComplete()
            }
        } label: {
            HStack(spacing: 8) {
                Text(currentIndex == viewModel.pages.count - 1 ? "Get Started" : "Next")
                Image(systemName: currentIndex == viewModel.pages.count - 1 ? "checkmark" : "arrow.right")
                    .font(.subheadline.weight(.bold))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .appPrimaryButton()
        }
        .padding(.horizontal, 24)
    }
}

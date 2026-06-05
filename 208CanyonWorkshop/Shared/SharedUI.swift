import SwiftUI

enum AppDesign {
    static var screenGradient: LinearGradient {
        LinearGradient(
            colors: [Color("AppBackground"), Color("AppSurface"), Color("AppBackground")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [Color("AppSurface"), Color("AppBackground").opacity(0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color("AppPrimary"), Color("AppAccent")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var accentStroke: LinearGradient {
        LinearGradient(
            colors: [Color("AppAccent").opacity(0.45), Color("AppPrimary").opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            AppDesign.screenGradient

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color("AppPrimary").opacity(0.22), Color.clear],
                        center: .center,
                        startRadius: 8,
                        endRadius: 180
                    )
                )
                .frame(width: 320, height: 320)
                .offset(x: -120, y: -220)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color("AppAccent").opacity(0.16), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 160
                    )
                )
                .frame(width: 280, height: 280)
                .offset(x: 140, y: 320)
        }
        .ignoresSafeArea()
    }
}

private struct AppCardSurfaceModifier: ViewModifier {
    let radius: CGFloat
    let elevated: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(AppDesign.cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(AppDesign.accentStroke, lineWidth: 1)
            )
            .modifier(AppShadowModifier(enabled: elevated, radius: 6, y: 3))
    }
}

struct AppShadowModifier: ViewModifier {
    let enabled: Bool
    let radius: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        if enabled {
            content
                .compositingGroup()
                .shadow(color: Color("AppBackground").opacity(0.42), radius: radius, x: 0, y: y)
        } else {
            content
        }
    }
}

extension View {
    func appElevatedCard(radius: CGFloat = 16) -> some View {
        modifier(AppCardSurfaceModifier(radius: radius, elevated: true))
    }

    func appSurface(radius: CGFloat = 14) -> some View {
        modifier(AppCardSurfaceModifier(radius: radius, elevated: false))
    }

    func appPanel(radius: CGFloat = 16) -> some View {
        padding(14)
            .appElevatedCard(radius: radius)
    }

    func appChip(active: Bool) -> some View {
        font(.caption.bold())
            .foregroundStyle(Color("AppTextPrimary"))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                Capsule(style: .continuous)
                    .fill(
                        active
                        ? AnyShapeStyle(AppDesign.primaryGradient)
                        : AnyShapeStyle(AppDesign.cardGradient)
                    )
            }
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color("AppAccent").opacity(active ? 0.5 : 0.2), lineWidth: 1)
            }
    }

    func appPrimaryButton() -> some View {
        font(.headline)
            .foregroundStyle(Color("AppTextPrimary"))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppDesign.primaryGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color("AppAccent").opacity(0.45), lineWidth: 1)
            )
            .modifier(AppShadowModifier(enabled: true, radius: 5, y: 2))
    }

    func appFAB() -> some View {
        background(AppDesign.primaryGradient, in: Circle())
            .overlay(Circle().stroke(Color("AppAccent").opacity(0.55), lineWidth: 1))
            .modifier(AppShadowModifier(enabled: true, radius: 8, y: 4))
    }
}

struct AppCard<Content: View>: View {
    let elevated: Bool
    let content: Content

    init(elevated: Bool = true, @ViewBuilder content: () -> Content) {
        self.elevated = elevated
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .modifier(AppCardSurfaceModifier(radius: 16, elevated: elevated))
    }
}

struct AppSectionTitle: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AppSearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color("AppAccent"))
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .appSurface(radius: 12)
    }
}

struct SuccessBadgeOverlay: View {
    @Binding var isVisible: Bool

    var body: some View {
        VStack {
            if isVisible {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(Color("AppAccent"))
                    .padding(18)
                    .appElevatedCard(radius: 20)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isVisible)
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)), y: 0))
    }
}

struct AchievementBannerView: View {
    let achievement: AchievementDefinition

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.title2)
                .foregroundStyle(Color("AppAccent"))
            VStack(alignment: .leading, spacing: 3) {
                Text("Achievement Unlocked")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                Text(achievement.title)
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
            }
            Spacer()
        }
        .padding(14)
        .appElevatedCard(radius: 16)
        .padding(.horizontal, 16)
    }
}

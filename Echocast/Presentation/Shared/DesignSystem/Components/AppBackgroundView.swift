import SwiftUI

struct AppBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(Colors.accent.opacity(colorScheme == .dark ? 0.18 : 0.12))
                .frame(width: Size.backgroundAccentCircle, height: Size.backgroundAccentCircle)
                .blur(radius: Spacing.blurRadius60)
                .offset(x: 140, y: -220)
        }
        .ignoresSafeArea()
    }

    private var backgroundColors: [Color] {
        if colorScheme == .dark {
            return [
                Colors.backgroundPrimary,
                Colors.backgroundPrimary,
                Colors.accent.opacity(0.12)
            ]
        }

        return [
            Colors.accent.opacity(0.14),
            Colors.backgroundPrimary,
            Colors.backgroundPrimary
        ]
    }
}

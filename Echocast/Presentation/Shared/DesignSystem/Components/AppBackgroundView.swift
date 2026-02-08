import SwiftUI

struct AppBackgroundView: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [
                    Colors.backgroundPrimary,
                    Colors.surfaceSecondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Colors.glowPrimary)
                .frame(
                    width: Size.backgroundAccentCircle,
                    height: Size.backgroundAccentCircle
                )
                .blur(radius: Spacing.blurRadius60)
                .offset(
                    x: Size.backgroundAccentCircle * 0.25,
                    y: -(Size.backgroundAccentCircle * 0.35)
                )
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

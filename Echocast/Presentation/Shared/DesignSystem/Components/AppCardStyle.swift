import SwiftUI

private struct AppCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous)
                    .fill(Colors.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous)
                    .stroke(Colors.cardBorder, lineWidth: 1)
            )
            .shadow(color: Colors.cardShadow, radius: Spacing.shadowRadius14, x: 0, y: 6)
    }
}

extension View {
    func appCardStyle() -> some View {
        modifier(AppCardModifier())
    }
}

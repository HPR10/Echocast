import SwiftUI

private struct AppCardModifier: ViewModifier {
    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous)
    }

    func body(content: Content) -> some View {
        content
            .padding(Spacing.cardPadding)
            .glassEffect(in: .rect(cornerRadius: Spacing.cornerRadius))
            .overlay {
                cardShape
                    .stroke(Colors.cardBorder, lineWidth: 0.8)
            }
    }
}

extension View {
    func appCardStyle() -> some View {
        modifier(AppCardModifier())
    }
}

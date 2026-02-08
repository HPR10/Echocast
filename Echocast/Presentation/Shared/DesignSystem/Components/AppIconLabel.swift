import SwiftUI

struct AppIconLabel: View {
    @Environment(\.colorScheme) private var colorScheme

    let text: String
    let symbol: String
    var font: Font = Typography.title
    var textRole: Colors.TextRole = .primary
    var surface: Colors.SurfaceRole = .card
    var alignment: Alignment = .leading

    var body: some View {
        Label(text, systemImage: symbol)
            .font(font)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(Colors.text(textRole, on: surface, scheme: colorScheme))
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity, alignment: alignment)
    }
}

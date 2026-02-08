import SwiftUI

struct AppGlassButton<Label: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let action: () -> Void
    let label: () -> Label
    var tint: Color = Colors.brand300
    var cornerRadius: CGFloat = Spacing.cornerRadius
    var expands: Bool = true
    var controlSize: ControlSize = .large
    var isDisabled: Bool = false
    var textColor: Color? = nil

    var body: some View {
        Button(action: action) {
            label()
                .frame(maxWidth: expands ? .infinity : nil)
                .padding(.vertical, Spacing.space12)
                .padding(.horizontal, Spacing.space16)
        }
        .glassEffect(
            .regular.tint(tint).interactive(),
            in: .rect(cornerRadius: cornerRadius)
        )
        .foregroundStyle(textColor ?? Colors.text(.primary, on: .accent, scheme: colorScheme))
        .buttonStyle(.plain)
        .controlSize(controlSize)
        .disabled(isDisabled)
    }
}

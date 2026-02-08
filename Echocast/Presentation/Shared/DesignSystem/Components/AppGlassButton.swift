import SwiftUI

struct AppGlassButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label
    var tint: Color = Colors.brand300
    var cornerRadius: CGFloat = Spacing.cornerRadius
    var expands: Bool = true
    var controlSize: ControlSize = .large
    var isDisabled: Bool = false
    var textColor: Color? = nil

    private var buttonShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        Button(action: action) {
            label()
                .frame(maxWidth: expands ? .infinity : nil)
        }
        .buttonStyle(.glass(.regular.tint(tint).interactive()))
        .buttonBorderShape(.roundedRectangle(radius: cornerRadius))
        .contentShape(buttonShape)
        .foregroundStyle(textColor ?? Color.primary)
        .controlSize(controlSize)
        .disabled(isDisabled)
    }
}

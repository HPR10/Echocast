import SwiftUI

struct AppButton: View {
    enum Variant {
        case prominent
        case glass
    }

    enum IconPlacement {
        case leading
        case trailing
    }

    let title: String
    let action: () -> Void
    var symbol: String? = nil
    var iconPlacement: IconPlacement = .trailing
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var expands: Bool = true
    var variant: Variant = .prominent
    var controlSize: ControlSize = .regular
    var glassTint: Color = Colors.brand300

    private var effectiveDisabled: Bool {
        isDisabled || isLoading
    }

    var body: some View {
        Group {
            switch variant {
            case .prominent:
                Button(action: action) {
                    labelContent
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.roundedRectangle(radius: Spacing.cornerRadius))
                .tint(Colors.tintPrimary)
                .controlSize(controlSize)
                .frame(maxWidth: expands ? .infinity : nil)
                .disabled(effectiveDisabled)
            case .glass:
                AppGlassButton(
                    action: action,
                    label: { labelContent },
                    tint: glassTint,
                    cornerRadius: Spacing.cornerRadius,
                    expands: expands,
                    controlSize: controlSize,
                    isDisabled: effectiveDisabled
                )
            }
        }
    }

    @ViewBuilder
    private var labelContent: some View {
        HStack(spacing: Spacing.space8) {
            if iconPlacement == .leading {
                iconContent
            }

            Text(title)
                .font(Typography.buttonLabel)

            if iconPlacement == .trailing {
                iconContent
            }
        }
    }

    @ViewBuilder
    private var iconContent: some View {
        if isLoading {
            ProgressView()
                .controlSize(.small)
                .tint(loadingTint)
        } else if let symbol {
            Image(systemName: symbol)
                .imageScale(.medium)
        }
    }

    private var loadingTint: Color {
        switch variant {
        case .prominent:
            return Colors.tintOnAccent
        case .glass:
            return Colors.tintPrimary
        }
    }
}

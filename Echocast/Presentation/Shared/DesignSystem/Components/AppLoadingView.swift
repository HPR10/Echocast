import SwiftUI

struct AppLoadingView: View {
    enum Style {
        case stacked
        case inline
    }

    @Environment(\.colorScheme) private var colorScheme

    let message: String
    var subtitle: String? = nil
    var surface: Colors.SurfaceRole = .appBackground
    var controlSize: ControlSize = .large
    var style: Style = .stacked

    var body: some View {
        if style == .inline {
            HStack(spacing: Spacing.space8) {
                ProgressView()
                    .controlSize(controlSize)
                    .progressViewStyle(.circular)
                    .tint(Colors.tintPrimary)

                Text(message)
                    .font(Typography.caption)
                    .foregroundStyle(
                        Colors.text(.secondary, on: surface, scheme: colorScheme)
                    )
                    .multilineTextAlignment(.leading)
            }
        } else {
            VStack(spacing: Spacing.space12) {
                ProgressView()
                    .controlSize(controlSize)
                    .progressViewStyle(.circular)
                    .tint(Colors.tintPrimary)

                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(
                        Colors.text(.secondary, on: surface, scheme: colorScheme)
                    )

                if let subtitle {
                    Text(subtitle)
                        .font(Typography.meta)
                        .foregroundStyle(
                            Colors.text(.tertiary, on: surface, scheme: colorScheme)
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.cardPadding)
            .glassEffect(in: .rect(cornerRadius: Spacing.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous)
                    .stroke(Colors.cardBorder, lineWidth: 0.8)
            }
        }
    }
}

import SwiftUI

enum Colors {
    enum TextRole {
        case primary
        case secondary
        case tertiary
        case inverse
    }

    enum SurfaceRole {
        case appBackground
        case card
        case accent
    }

    // Study palette selected:
    // #021024, #052659, #5483B3, #7DA0CA, #C1E8FF
    static let brand950 = Color(red: 0.0078, green: 0.0627, blue: 0.1412) // #021024
    static let brand800 = Color(red: 0.0196, green: 0.1490, blue: 0.3490) // #052659
    static let brand500 = Color(red: 0.3294, green: 0.5137, blue: 0.7020) // #5483B3
    static let brand300 = Color(red: 0.4902, green: 0.6275, blue: 0.7922) // #7DA0CA
    static let brand100 = Color(red: 0.7569, green: 0.9098, blue: 1.0000) // #C1E8FF

    static let accent = brand500
    static let cardBorder = brand300.opacity(0.35)
    static let cardShadow = brand950.opacity(0.20)

    static func text(
        _ role: TextRole = .primary,
        on surface: SurfaceRole,
        scheme: ColorScheme
    ) -> Color {
        switch surface {
        case .appBackground, .card:
            let isDark = scheme == .dark

            switch role {
            case .primary:
                return isDark ? .white : brand950
            case .secondary:
                return isDark ? .white.opacity(0.78) : brand500
            case .tertiary:
                return isDark ? .white.opacity(0.62) : brand300
            case .inverse:
                return isDark ? brand950 : brand100
            }
        case .accent:
            switch role {
            case .primary:
                return brand100
            case .secondary:
                return brand300
            case .tertiary:
                return brand500
            case .inverse:
                return brand950
            }
        }
    }

    static func textPrimary(on surface: SurfaceRole, scheme: ColorScheme) -> Color {
        text(.primary, on: surface, scheme: scheme)
    }

    static func textSecondary(on surface: SurfaceRole, scheme: ColorScheme) -> Color {
        text(.secondary, on: surface, scheme: scheme)
    }

    static func textTertiary(on surface: SurfaceRole, scheme: ColorScheme) -> Color {
        text(.tertiary, on: surface, scheme: scheme)
    }

    static let tintPrimary = brand500
    static let tintOnAccent = brand100
    static let feedbackError = Color(red: 0.8000, green: 0.1800, blue: 0.2400)
    static let surfaceMuted = brand300.opacity(0.22)
    static let surfaceSubtle = brand100.opacity(0.30)
    static let borderSubtle = brand300.opacity(0.28)
    static let iconMuted = brand800.opacity(0.65)
    static let glowPrimary = brand500.opacity(0.25)
    static let favoriteActive = Color.yellow
    static let favoriteInactive = brand300
    static let inputShadow = Color.black.opacity(0.08)
    static let artworkShadow = Color.black.opacity(0.12)

    static let backgroundPrimary = Color(.systemBackground)
    static let surfaceSecondary = Color(.secondarySystemBackground)
}

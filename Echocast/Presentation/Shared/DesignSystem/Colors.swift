import SwiftUI

enum Colors {
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

    static let textPrimary = brand950
    static let textSecondary = brand500
    static let textTertiary = brand300
    static let tintPrimary = brand500
    static let tintOnAccent = brand100
    static let feedbackError = Color(red: 0.8000, green: 0.1800, blue: 0.2400)
    static let surfaceMuted = brand300.opacity(0.22)
    static let surfaceSubtle = brand100.opacity(0.30)
    static let borderSubtle = brand300.opacity(0.28)
    static let iconMuted = brand800.opacity(0.65)
    static let glowPrimary = brand500.opacity(0.25)
    static let favoriteActive = Color.yellow
    static let favoriteInactive = textSecondary
    static let inputShadow = Color.black.opacity(0.08)
    static let artworkShadow = Color.black.opacity(0.12)

    static let backgroundPrimary = Color(.systemBackground)
    static let surfaceSecondary = Color(.secondarySystemBackground)
}

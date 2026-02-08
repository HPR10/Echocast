import SwiftUI

enum Typography {
    static let heroTitle = Font.system(size: 30, weight: .bold, design: .rounded)
    static let sectionTitle = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let title = Font.system(size: 17, weight: .semibold, design: .rounded)

    static let body = Font.subheadline
    static let meta = Font.footnote
    static let caption = Font.caption

    static let screenTitle = Font.title2.weight(.bold)
    static let buttonLabel = Font.headline.weight(.semibold)
    static let bodyRegular = Font.body
    static let playerTitle = Font.title3.weight(.semibold)

    static let iconMiniControl = Font.system(size: 16, weight: .semibold)
    static let iconMiniPlaceholder = Font.system(size: 14, weight: .semibold)
    static let iconFavorite = Font.title2.weight(.semibold)
    static let iconTransportSecondary = Font.system(size: 32, weight: .semibold)
    static let iconTransportPrimary = Font.system(size: 40, weight: .bold)
    static let iconUtility = Font.system(size: 20, weight: .semibold)
    static let iconArtworkFallback = Font.title2
}

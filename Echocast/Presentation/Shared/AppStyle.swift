//
//  AppStyle.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 21/12/25.
//

import SwiftUI

enum AppStyle {
    static let horizontalPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 18
    static let accent = Color(red: 0.94, green: 0.42, blue: 0.2)
    static let cardBorder = Color(.separator).opacity(0.35)
    static let cardShadow = Color.black.opacity(0.12)

    static let heroTitleFont = Font.system(size: 30, weight: .bold, design: .rounded)
    static let sectionTitleFont = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let cardTitleFont = Font.system(size: 17, weight: .semibold, design: .rounded)
}

struct AppBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(AppStyle.accent.opacity(colorScheme == .dark ? 0.18 : 0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: 140, y: -220)
        }
        .ignoresSafeArea()
    }

    private var backgroundColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(.systemBackground),
                Color(.systemBackground),
                AppStyle.accent.opacity(0.12)
            ]
        }

        return [
            AppStyle.accent.opacity(0.14),
            Color(.systemBackground),
            Color(.systemBackground)
        ]
    }
}

private struct AppCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppStyle.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                    .stroke(AppStyle.cardBorder, lineWidth: 1)
            )
            .shadow(color: AppStyle.cardShadow, radius: 14, x: 0, y: 6)
    }
}

extension View {
    func appCardStyle() -> some View {
        modifier(AppCardModifier())
    }
}

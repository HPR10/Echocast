//
//  PodcastArtworkView.swift
//  Echocast
//
//  Created by OpenAI Assistant on 2025-xx-xx.
//

import SwiftUI
import NukeUI

struct PodcastArtworkView: View {
    let imageURL: URL?
    let size: CGFloat
    var cornerRadius: CGFloat = Spacing.radius16

    private var artworkShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        LazyImage(url: imageURL) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            } else if state.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.secondary)
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .glassEffect(in: .rect(cornerRadius: cornerRadius))
        .overlay {
            artworkShape
                .stroke(Colors.cardBorder, lineWidth: 0.8)
        }
        .clipShape(artworkShape)
    }

    private var placeholder: some View {
        artworkShape
            .fill(Colors.surfaceSubtle)
            .overlay {
                Image(systemName: SFSymbols.microphoneFilled)
                    .font(Typography.iconArtworkFallback)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Colors.iconMuted)
            }
    }
}

#Preview("Artwork (isolado)") {
    PodcastArtworkView(
        imageURL: URL(string: "https://example.com/artwork.jpg"),
        size: Size.previewArtwork
    )
    .padding()
}

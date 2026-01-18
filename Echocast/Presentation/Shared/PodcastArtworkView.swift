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
    var cornerRadius: CGFloat = 16

    var body: some View {
        LazyImage(url: imageURL) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            } else if state.isLoading {
                ProgressView()
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.gray.opacity(0.2))
            .overlay {
                Image(systemName: "mic.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.gray.opacity(0.7))
            }
    }
}

#Preview("Artwork (isolado)") {
    PodcastArtworkView(
        imageURL: URL(string: "https://example.com/artwork.jpg"),
        size: 200
    )
    .padding()
}

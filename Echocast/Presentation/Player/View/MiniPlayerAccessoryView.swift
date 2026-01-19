//
//  MiniPlayerAccessoryView.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 19/01/26.
//

import SwiftUI
import NukeUI

struct MiniPlayerAccessoryView: View {
    let viewModel: PlayerViewModel
    let podcastImageURL: URL?
    let onTap: () -> Void

    private let artworkSize: CGFloat = 36

    var body: some View {
        @Bindable var viewModel = viewModel

        HStack(spacing: 12) {
            MiniArtworkView(imageURL: podcastImageURL, size: artworkSize)

            Text(viewModel.episode.title)
                .font(AppTypography.body)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 8)

            Button {
                viewModel.togglePlayback()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Capsule())
        .gesture(
            TapGesture()
                .onEnded { onTap() },
            including: .gesture
        )
    }
}

private struct MiniArtworkView: View {
    let imageURL: URL?
    let size: CGFloat

    var body: some View {
        LazyImage(url: imageURL) { state in
            Group {
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.gray.opacity(0.2))
                        Image(systemName: "mic.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.gray.opacity(0.7))
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

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

    private let artworkSize: CGFloat = Size.miniPlayerArtwork

    var body: some View {
        @Bindable var viewModel = viewModel

        HStack(spacing: Spacing.space12) {
            MiniArtworkView(imageURL: podcastImageURL, size: artworkSize)

            Text(viewModel.episode.title)
                .font(Typography.body)
                .foregroundStyle(Colors.textPrimary)
                .lineLimit(1)

            Spacer(minLength: Spacing.space8)

            Button {
                viewModel.togglePlayback()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(Typography.iconMiniControl)
                    .frame(width: Size.miniPlayerControl, height: Size.miniPlayerControl)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.space16)
        .padding(.vertical, Spacing.space8)
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
                        RoundedRectangle(cornerRadius: Spacing.radius8, style: .continuous)
                            .fill(Colors.surfaceMuted)
                        Image(systemName: "mic.fill")
                            .font(Typography.iconMiniPlaceholder)
                            .foregroundStyle(Colors.iconMuted)
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.radius8, style: .continuous))
    }
}

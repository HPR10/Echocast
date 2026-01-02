//
//  FavoritesView.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 12/03/25.
//

import SwiftUI

struct FavoritesView: View {
    @State private var viewModel: FavoritesViewModel

    init(viewModel: FavoritesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Group {
                if viewModel.favorites.isEmpty {
                    ContentUnavailableView(
                        "Favoritos",
                        systemImage: "star.fill",
                        description: Text("Adicione episodios aos favoritos para ve-los aqui.")
                    )
                } else {
                    List {
                        ForEach(viewModel.favorites) { favorite in
                            NavigationLink {
                                PlayerRouteView(
                                    episode: favorite.episode,
                                    podcastTitle: favorite.podcastTitle
                                )
                            } label: {
                                FavoriteEpisodeRow(favorite: favorite)
                            }
                        }
                        .onDelete { indexSet in
                            Task { @MainActor in
                                for index in indexSet {
                                    let favorite = viewModel.favorites[index]
                                    await viewModel.remove(playbackKey: favorite.playbackKey)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Favoritos")
            .task {
                await viewModel.refresh()
            }
        }
    }
}

private struct FavoriteEpisodeRow: View {
    let favorite: FavoriteEpisode

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(favorite.title)
                .font(.headline)
                .lineLimit(2)

            Text(favorite.podcastTitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if let summary = favorite.summary, !summary.isEmpty {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                if let publishedAt = favorite.publishedAt {
                    Text(publishedAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let duration = favorite.duration {
                    Text(formatDuration(duration))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = seconds >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: seconds) ?? ""
    }
}

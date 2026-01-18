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
            ZStack {
                AppBackgroundView()

                Group {
                    if viewModel.favorites.isEmpty {
                        ContentUnavailableView(
                            "Favoritos",
                            systemImage: "star.fill",
                            description: Text("Adicione episodios aos favoritos para ve-los aqui.")
                        )
                    } else {
                        List {
                            ForEach(viewModel.favorites, id: \.id) { favorite in
                                NavigationLink {
                                    PlayerRouteView(
                                        episode: favorite.episode,
                                        podcastTitle: favorite.podcastTitle,
                                        podcastImageURL: favorite.podcastImageURL
                                    )
                                } label: {
                                    FavoriteEpisodeRow(favorite: favorite)
                                }
                            }
                            .onDelete { indexSet in
                                let favoritesSnapshot = viewModel.favorites
                                let playbackKeys: [String] = indexSet.compactMap { (index) -> String? in
                                    guard favoritesSnapshot.indices.contains(index) else { return nil }
                                    return favoritesSnapshot[index].playbackKey as String?
                                }

                                Task { @MainActor in
                                    guard !playbackKeys.isEmpty else { return }
                                    await viewModel.remove(playbackKeys: playbackKeys)
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                    }
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

// MARK: - Previews

#Preview("Favoritos - Com dados") {
    FavoritesPreviewFactory.make()
}

@MainActor
private enum FavoritesPreviewFactory {
    static func make() -> some View {
        let sampleFavorites = [
            FavoriteEpisode(
                playbackKey: "preview-1",
                title: "Clean Architecture na prática",
                podcastTitle: "Tech BR",
                podcastImageURL: URL(string: "https://example.com/backend.png"),
                summary: "Resumo rápido sobre camadas e casos de uso.",
                audioURL: URL(string: "https://example.com/episode.mp3"),
                duration: 2_700,
                publishedAt: Date().addingTimeInterval(-86_400),
                addedAt: Date().addingTimeInterval(-3_600)
            ),
            FavoriteEpisode(
                playbackKey: "preview-2",
                title: "SwiftUI avançado",
                podcastTitle: "Swift Talks",
                podcastImageURL: URL(string: "https://example.com/swift.png"),
                summary: "Discussão sobre performance e arquitetura em SwiftUI.",
                audioURL: URL(string: "https://example.com/episode2.mp3"),
                duration: 3_600,
                publishedAt: Date().addingTimeInterval(-172_800),
                addedAt: Date()
            )
        ]
        let favoritesViewModel = FavoritesViewModel(
            manageFavoritesUseCase: ManageFavoriteEpisodesUseCase(
                repository: PreviewFavoriteEpisodesRepository(items: sampleFavorites)
            )
        )
        let playerCoordinator = PlayerCoordinator(
            manageProgressUseCase: ManagePlaybackProgressUseCase(
                repository: MockPlaybackProgressRepository()
            ),
            playerService: MockAudioPlayerService()
        )

        return FavoritesView(viewModel: favoritesViewModel)
            .environment(favoritesViewModel)
            .environment(playerCoordinator)
    }
}

private final class PreviewFavoriteEpisodesRepository: FavoriteEpisodesRepositoryProtocol {
    private var items: [FavoriteEpisode]

    init(items: [FavoriteEpisode]) {
        self.items = items
    }

    func list() async -> [FavoriteEpisode] {
        items
    }

    func save(_ episode: FavoriteEpisode) async {
        items.removeAll { $0.playbackKey == episode.playbackKey }
        items.append(episode)
    }

    func remove(playbackKey: String) async {
        items.removeAll { $0.playbackKey == playbackKey }
    }

    func exists(playbackKey: String) async -> Bool {
        items.contains { $0.playbackKey == playbackKey }
    }
}

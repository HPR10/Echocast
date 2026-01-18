//
//  RootTabView.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    @State private var addPodcastViewModel: AddPodcastViewModel
    @State private var favoritesViewModel: FavoritesViewModel
    @State private var technologySearchViewModel: TechnologySearchViewModel

    init(
        addPodcastViewModel: AddPodcastViewModel,
        favoritesViewModel: FavoritesViewModel,
        technologySearchViewModel: TechnologySearchViewModel
    ) {
        _addPodcastViewModel = State(initialValue: addPodcastViewModel)
        _favoritesViewModel = State(initialValue: favoritesViewModel)
        _technologySearchViewModel = State(initialValue: technologySearchViewModel)
    }

    var body: some View {
        TabView {
            AddPodcastView(viewModel: addPodcastViewModel)
                .tabItem {
                    Label("Início", systemImage: "house.fill")
                }

            FavoritesView(viewModel: favoritesViewModel)
                .tabItem {
                    Label("Favoritos", systemImage: "star.fill")
                }

            TechnologySearchView(viewModel: technologySearchViewModel)
                .tabItem {
                    Label("Buscar", systemImage: "magnifyingglass")
                }
        }
    }
}

// MARK: - Previews

#Preview("App - Claro") {
    RootTabPreviewFactory.make()
}

#Preview("App - Escuro") {
    RootTabPreviewFactory.make(preferredColorScheme: .dark)
}

@MainActor
private enum RootTabPreviewFactory {
    static func make(preferredColorScheme: ColorScheme? = nil) -> AnyView {
        struct PreviewPodcastDiscoveryService: PodcastDiscoveryServiceProtocol {
            func fetchTechnologyPodcasts(limit: Int, offset: Int) async throws -> [DiscoveredPodcast] {
                guard offset == 0 else { return [] }
                return [
                    DiscoveredPodcast(
                        id: 1,
                        title: "Swift Talks",
                        author: "Swift Team",
                        imageURL: URL(string: "https://example.com/swift.png"),
                        feedURL: URL(string: "https://feeds.simplecast.com/54nAGcIl")!
                    ),
                    DiscoveredPodcast(
                        id: 2,
                        title: "Backend em Foco",
                        author: "Tech BR",
                        imageURL: URL(string: "https://example.com/backend.png"),
                        feedURL: URL(string: "https://rss.art19.com/the-daily")!
                    )
                ]
            }
        }

        let container = try! ModelContainer(
            for: FeedHistoryItem.self,
            PodcastEntity.self,
            EpisodeEntity.self,
            FavoriteEpisodeEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let previewFavorites = [
            FavoriteEpisodeEntity(
                playbackKey: "preview-1",
                title: "Clean Architecture na prática",
                podcastTitle: "Tech BR",
                podcastImageURL: "https://example.com/backend.png",
                summary: "Resumo rápido sobre camadas e casos de uso.",
                audioURL: "https://example.com/episode.mp3",
                duration: 2_700,
                publishedAt: Date().addingTimeInterval(-86_400),
                addedAt: Date().addingTimeInterval(-3_600)
            ),
            FavoriteEpisodeEntity(
                playbackKey: "preview-2",
                title: "SwiftUI avançado",
                podcastTitle: "Swift Talks",
                podcastImageURL: "https://example.com/swift.png",
                summary: "Discussão sobre performance e arquitetura em SwiftUI.",
                audioURL: "https://example.com/episode2.mp3",
                duration: 3_600,
                publishedAt: Date().addingTimeInterval(-172_800),
                addedAt: Date()
            )
        ]
        previewFavorites.forEach { container.mainContext.insert($0) }
        try? container.mainContext.save()
        let feedService = MockFeedService(delay: 0)
        let loadPodcastUseCase = LoadPodcastFromRSSUseCase(
            feedService: feedService
        )
        let podcastRepository = PodcastRepository(
            modelContext: container.mainContext
        )
        let addPodcastViewModel = AddPodcastViewModel(
            manageHistoryUseCase: ManageFeedHistoryUseCase(
                repository: FeedHistoryRepository(
                    modelContext: container.mainContext
                )
            ),
            syncPodcastUseCase: SyncPodcastFeedUseCase(
                loadPodcastUseCase: loadPodcastUseCase,
                repository: podcastRepository
            )
        )
        let favoritesViewModel = FavoritesViewModel(
            manageFavoritesUseCase: ManageFavoriteEpisodesUseCase(
                repository: FavoriteEpisodesRepository(
                    modelContext: container.mainContext
                )
            )
        )
        let technologySearchViewModel = TechnologySearchViewModel(
            fetchUseCase: FetchTechnologyPodcastsUseCase(
                discoveryService: PreviewPodcastDiscoveryService()
            ),
            syncPodcastUseCase: SyncPodcastFeedUseCase(
                loadPodcastUseCase: loadPodcastUseCase,
                repository: podcastRepository
            )
        )
        let playerCoordinator = PlayerCoordinator(
            manageProgressUseCase: ManagePlaybackProgressUseCase(
                repository: PlaybackProgressRepository(
                    modelContext: container.mainContext
                )
            ),
            playerService: MockAudioPlayerService()
        )

        let view = RootTabView(
            addPodcastViewModel: addPodcastViewModel,
            favoritesViewModel: favoritesViewModel,
            technologySearchViewModel: technologySearchViewModel
        )
        .modelContainer(container)
        .environment(playerCoordinator)
        .environment(favoritesViewModel)

        if let preferredColorScheme {
            return AnyView(view.preferredColorScheme(preferredColorScheme))
        }
        return AnyView(view)
    }
}

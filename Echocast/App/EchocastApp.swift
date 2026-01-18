//
//  EchocastApp.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 10/12/25.
//

import SwiftUI
import SwiftData

@main
struct EchocastApp: App {
    let container: ModelContainer
    let addPodcastViewModel: AddPodcastViewModel
    let playbackProgressUseCase: ManagePlaybackProgressUseCase
    let audioPlayerService: AudioPlayerService
    let playerCoordinator: PlayerCoordinator
    let favoritesViewModel: FavoritesViewModel
    let technologySearchViewModel: TechnologySearchViewModel
    let studyFlowViewModel: StudyFlowViewModel

    init() {
        do {
            container = try ModelContainer(
                for: FeedHistoryItem.self,
                PodcastEntity.self,
                EpisodeEntity.self,
                FavoriteEpisodeEntity.self
            )
            let feedService = FeedService()
            let imageCacheService = ImageCacheService()
            imageCacheService.configureSharedPipeline()
            let loadPodcastUseCase = LoadPodcastFromRSSUseCase(
                feedService: feedService
            )
            let resolveArtworkUseCase = ResolvePodcastArtworkUseCase(
                feedService: feedService
            )
            let podcastRepository = PodcastRepository(
                modelContext: container.mainContext
            )
            let playbackProgressUseCase = ManagePlaybackProgressUseCase(
                repository: PlaybackProgressRepository(
                    modelContext: container.mainContext
                )
            )
            let podcastDiscoveryService = PodcastIndexDiscoveryService(
                apiKey: "Q8GJUAQFZSVEF8MNH6KE",
                apiSecret: "kDFc3KAPNMJ5F^ZBDVh4C^xCebmag#QC2fjr6Yhf"
            )
            let manageFavoriteEpisodesUseCase = ManageFavoriteEpisodesUseCase(
                repository: FavoriteEpisodesRepository(
                    modelContext: container.mainContext
                )
            )
            favoritesViewModel = FavoritesViewModel(
                manageFavoritesUseCase: manageFavoriteEpisodesUseCase
            )
            technologySearchViewModel = TechnologySearchViewModel(
                fetchUseCase: FetchTechnologyPodcastsUseCase(
                    discoveryService: podcastDiscoveryService
                ),
                syncPodcastUseCase: SyncPodcastFeedUseCase(
                    loadPodcastUseCase: loadPodcastUseCase,
                    repository: podcastRepository
                ),
                resolveArtworkUseCase: resolveArtworkUseCase
            )
            studyFlowViewModel = StudyFlowViewModel(
                getCatalogUseCase: GetCuratedCatalogUseCase(
                    repository: CuratedCatalogRepository()
                ),
                searchUseCase: SearchPodcastsUseCase(
                    discoveryService: podcastDiscoveryService
                )
            )
            let audioPlayerService = AudioPlayerService()
            addPodcastViewModel = AddPodcastViewModel(
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
            self.playbackProgressUseCase = playbackProgressUseCase
            self.audioPlayerService = audioPlayerService
            playerCoordinator = PlayerCoordinator(
                manageProgressUseCase: playbackProgressUseCase,
                playerService: audioPlayerService
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(
                studyFlowViewModel: studyFlowViewModel,
                addPodcastViewModel: addPodcastViewModel,
                favoritesViewModel: favoritesViewModel,
                technologySearchViewModel: technologySearchViewModel
            )
            .environment(playerCoordinator)
            .environment(favoritesViewModel)
        }
        .modelContainer(container)
    }
}

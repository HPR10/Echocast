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
    let downloadsViewModel: DownloadsViewModel

    init() {
        do {
            container = try ModelContainer(
                for: FeedHistoryItem.self,
                PodcastEntity.self,
                EpisodeEntity.self,
                DownloadedEpisodeEntity.self
            )
            let feedService = FeedService()
            let imageCacheService = ImageCacheService()
            imageCacheService.configureSharedPipeline()
            let loadPodcastUseCase = LoadPodcastFromRSSUseCase(
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
            let downloadedFileProvider = DownloadedFileProvider()
            let downloadedEpisodesRepository = DownloadedEpisodesRepository(
                modelContext: container.mainContext,
                timeToLive: 30 * 24 * 60 * 60,
                fileProvider: downloadedFileProvider
            )
            let downloadService = EpisodeDownloadService(
                repository: downloadedEpisodesRepository,
                fileProvider: downloadedFileProvider
            )
            let enqueueDownloadUseCase = EnqueueEpisodeDownloadUseCase(
                downloadService: downloadService,
                repository: downloadedEpisodesRepository
            )
            let observeDownloadProgressUseCase = ObserveDownloadProgressUseCase(
                downloadService: downloadService
            )
            let listDownloadedEpisodesUseCase = ListDownloadedEpisodesUseCase(
                repository: downloadedEpisodesRepository
            )
            let deleteDownloadedEpisodeUseCase = DeleteDownloadedEpisodeUseCase(
                downloadService: downloadService,
                repository: downloadedEpisodesRepository
            )
            let resolvePlaybackSourceUseCase = ResolvePlaybackSourceUseCase(
                repository: downloadedEpisodesRepository
            )
            downloadsViewModel = DownloadsViewModel(
                listUseCase: listDownloadedEpisodesUseCase,
                observeProgressUseCase: observeDownloadProgressUseCase,
                deleteUseCase: deleteDownloadedEpisodeUseCase,
                enqueueUseCase: enqueueDownloadUseCase
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
                ),
                clearFeedCacheUseCase: ClearFeedCacheUseCase(
                    feedService: feedService
                ),
                clearImageCacheUseCase: ClearImageCacheUseCase(
                    imageCacheService: imageCacheService
                )
            )
            self.playbackProgressUseCase = playbackProgressUseCase
            self.audioPlayerService = audioPlayerService
            playerCoordinator = PlayerCoordinator(
                manageProgressUseCase: playbackProgressUseCase,
                playerService: audioPlayerService,
                resolvePlaybackSourceUseCase: resolvePlaybackSourceUseCase
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(
                addPodcastViewModel: addPodcastViewModel,
                downloadsViewModel: downloadsViewModel
            )
            .environment(playerCoordinator)
            .environment(downloadsViewModel)
        }
        .modelContainer(container)
    }
}

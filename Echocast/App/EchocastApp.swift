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

    init() {
        do {
            container = try ModelContainer(
                for: FeedHistoryItem.self,
                PodcastEntity.self,
                EpisodeEntity.self
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
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AddPodcastView(viewModel: addPodcastViewModel)
        }
        .modelContainer(container)
    }
}

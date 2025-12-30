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
            container = try ModelContainer(for: FeedHistoryItem.self)
            let feedService = FeedService()
            addPodcastViewModel = AddPodcastViewModel(
                manageHistoryUseCase: ManageFeedHistoryUseCase(
                    repository: FeedHistoryRepository(
                        modelContext: container.mainContext
                    )
                ),
                loadPodcastUseCase: LoadPodcastFromRSSUseCase(
                    feedService: feedService
                ),
                clearFeedCacheUseCase: ClearFeedCacheUseCase(
                    feedService: feedService
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

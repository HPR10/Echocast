//
//  EchocastApp.swift
//  Echocast
//
//  Created by actdigital on 10/12/25.
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
            addPodcastViewModel = AddPodcastViewModel(
                manageHistoryUseCase: ManageFeedHistoryUseCase(
                    repository: FeedHistoryRepository(
                        modelContext: container.mainContext
                    )
                ),
                loadPodcastUseCase: LoadPodcastFromRSSUseCase(
                    feedService: FeedService()
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

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

    init() {
        do {
            container = try ModelContainer(for: FeedHistoryItem.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AddPodcastView(
                viewModel: AddPodcastViewModel(
                    manageHistoryUseCase: ManageFeedHistoryUseCase(
                        repository: FeedHistoryRepository(
                            modelContext: container.mainContext
                        )
                    )
                )
            )
        }
        .modelContainer(container)
    }
}

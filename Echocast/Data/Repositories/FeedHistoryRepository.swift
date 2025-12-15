//
//  FeedHistoryRepository.swift
//  Echocast
//
//  Created by actdigital on 14/12/25.
//

import Foundation
import SwiftData

@MainActor
final class FeedHistoryRepository: FeedHistoryRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func add(_ url: String) {
        let newItem = FeedHistoryItem(url: url)
        modelContext.insert(newItem)
    }

    func delete(_ item: FeedHistoryItem) {
        modelContext.delete(item)
    }

    func findByURL(_ url: String) -> FeedHistoryItem? {
        let descriptor = FetchDescriptor<FeedHistoryItem>(
            predicate: #Predicate { $0.url == url }
        )
        return try? modelContext.fetch(descriptor).first
    }

    func deleteOldestExceeding(limit: Int, from items: [FeedHistoryItem]) {
        let excess = items.count - limit + 1
        guard excess > 0 else { return }

        let sortedByDate = items.sorted { $0.addedAt < $1.addedAt }
        for item in sortedByDate.prefix(excess) {
            modelContext.delete(item)
        }
    }
}

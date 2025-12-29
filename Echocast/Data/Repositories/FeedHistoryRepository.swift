//
//  FeedHistoryRepository.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 14/12/25.
//

import Foundation
import SwiftData

@MainActor
final class FeedHistoryRepository: FeedHistoryRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func add(_ url: String) async {
        let newItem = FeedHistoryItem(url: url)
        modelContext.insert(newItem)
        saveContext(action: "add")
    }

    func delete(_ item: FeedHistoryItem) async {
        modelContext.delete(item)
        saveContext(action: "delete")
    }

    func findByURL(_ url: String) async -> FeedHistoryItem? {
        let descriptor = FetchDescriptor<FeedHistoryItem>(
            predicate: #Predicate { $0.url == url }
        )
        return try? modelContext.fetch(descriptor).first
    }

    func deleteOldestExceeding(limit: Int) async {
        let descriptor = FetchDescriptor<FeedHistoryItem>(
            sortBy: [SortDescriptor(\.addedAt, order: .forward)]
        )
        guard let items = try? modelContext.fetch(descriptor) else { return }

        let excess = items.count - limit
        guard excess > 0 else { return }

        for item in items.prefix(excess) {
            modelContext.delete(item)
        }
        saveContext(action: "deleteOldestExceeding")
    }

    private func saveContext(action: String) {
        do {
            try modelContext.save()
        } catch {
            print("FeedHistoryRepository failed to \(action): \(error)")
        }
    }
}

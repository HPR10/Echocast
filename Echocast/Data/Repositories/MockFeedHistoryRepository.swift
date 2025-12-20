//
//  MockFeedHistoryRepository.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 20/12/25.

//

import Foundation

@MainActor
final class MockFeedHistoryRepository: FeedHistoryRepositoryProtocol {
    func add(_ url: String) async {}
    func delete(_ item: FeedHistoryItem) async {}
    func findByURL(_ url: String) async -> FeedHistoryItem? { nil }
    func deleteOldestExceeding(limit: Int, from items: [FeedHistoryItem]) async {}
}

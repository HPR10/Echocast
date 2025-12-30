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
    func deleteByURL(_ url: String) async {}
    func exists(_ url: String) async -> Bool { false }
    func deleteOldestExceeding(limit: Int) async {}
}

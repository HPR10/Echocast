//
//  FeedHistoryRepositoryProtocol.swift
//  Echocast
//
//  Created by actdigital on 14/12/25.
//

import Foundation

protocol FeedHistoryRepositoryProtocol: Sendable {
    func add(_ url: String) async
    func delete(_ item: FeedHistoryItem) async
    func findByURL(_ url: String) async -> FeedHistoryItem?
    func deleteOldestExceeding(limit: Int) async
}

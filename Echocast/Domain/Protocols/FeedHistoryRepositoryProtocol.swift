//
//  FeedHistoryRepositoryProtocol.swift
//  Echocast
//
//  Created by actdigital on 14/12/25.
//

import Foundation

protocol FeedHistoryRepositoryProtocol: Sendable {
    func add(_ url: String)
    func delete(_ item: FeedHistoryItem)
    func findByURL(_ url: String) -> FeedHistoryItem?
    func deleteOldestExceeding(limit: Int, from items: [FeedHistoryItem])
}

//
//  ManageFeedHistoryUseCase.swift
//  Echocast
//
//  Created by actdigital on 14/12/25.
//

import Foundation

final class ManageFeedHistoryUseCase: @unchecked Sendable {
    private let repository: FeedHistoryRepositoryProtocol
    private let maxItems: Int

    init(repository: FeedHistoryRepositoryProtocol, maxItems: Int = 10) {
        self.repository = repository
        self.maxItems = maxItems
    }

    func addURL(_ url: String?, currentHistory: [FeedHistoryItem]) {
        guard let url, !url.isEmpty else { return }

        if let existing = repository.findByURL(url) {
            repository.delete(existing)
        }

        repository.add(url)

        repository.deleteOldestExceeding(limit: maxItems, from: currentHistory)
    }
}

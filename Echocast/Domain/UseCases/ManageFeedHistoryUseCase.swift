//
//  ManageFeedHistoryUseCase.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 14/12/25.
//

import Foundation

@MainActor
final class ManageFeedHistoryUseCase {
    private let repository: FeedHistoryRepositoryProtocol
    private let maxItems: Int

    init(repository: FeedHistoryRepositoryProtocol, maxItems: Int = 10) {
        self.repository = repository
        self.maxItems = maxItems
    }

    func addURL(_ url: String) async {
        guard !url.isEmpty else { return }

        if let existing = await repository.findByURL(url) {
            await repository.delete(existing)
        }

        await repository.add(url)

        await repository.deleteOldestExceeding(limit: maxItems)
    }
}

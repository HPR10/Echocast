//
//  ClearFeedCacheUseCase.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 21/12/25.
//

import Foundation

@MainActor
final class ClearFeedCacheUseCase {
    private let feedService: FeedServiceProtocol

    init(feedService: FeedServiceProtocol) {
        self.feedService = feedService
    }

    func execute() async {
        await feedService.clearCache()
    }
}

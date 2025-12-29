//
//  LoadPodcastFromRSSUseCase.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 21/12/25.
//

import Foundation

@MainActor
final class LoadPodcastFromRSSUseCase {
    private let feedService: FeedServiceProtocol

    init(feedService: FeedServiceProtocol) {
        self.feedService = feedService
    }

    func execute(from url: URL) async throws -> Podcast {
        try await feedService.fetchFeed(from: url)
    }
}

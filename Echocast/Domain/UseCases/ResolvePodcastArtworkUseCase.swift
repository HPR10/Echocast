//
//  ResolvePodcastArtworkUseCase.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import Foundation

final class ResolvePodcastArtworkUseCase {
    private let feedService: FeedServiceProtocol

    init(feedService: FeedServiceProtocol) {
        self.feedService = feedService
    }

    func execute(feedURL: URL) async -> URL? {
        do {
            let podcast = try await feedService.fetchFeed(from: feedURL)
            return normalizedURL(from: podcast.imageURL)
        } catch {
            return nil
        }
    }

    private func normalizedURL(from url: URL?) -> URL? {
        guard let url else { return nil }
        if url.scheme == "http" {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.scheme = "https"
            return components?.url ?? url
        }
        return url
    }
}


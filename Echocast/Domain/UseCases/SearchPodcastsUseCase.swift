//
//  SearchPodcastsUseCase.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import Foundation

struct SearchPodcastsUseCase {
    private let discoveryService: PodcastDiscoveryServiceProtocol

    init(discoveryService: PodcastDiscoveryServiceProtocol) {
        self.discoveryService = discoveryService
    }

    func execute(
        query: String,
        limit: Int,
        offset: Int = 0
    ) async throws -> [DiscoveredPodcast] {
        try await discoveryService.searchPodcasts(matching: query, limit: limit, offset: offset)
    }
}

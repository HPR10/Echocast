//
//  FetchTechnologyPodcastsUseCase.swift
//  Echocast
//
//  Created by OpenAI Assistant on 27/02/25.
//

import Foundation

struct FetchTechnologyPodcastsUseCase {
    private let discoveryService: PodcastDiscoveryServiceProtocol

    init(discoveryService: PodcastDiscoveryServiceProtocol) {
        self.discoveryService = discoveryService
    }

    func execute() async throws -> [DiscoveredPodcast] {
        try await discoveryService.fetchTechnologyPodcasts()
    }
}

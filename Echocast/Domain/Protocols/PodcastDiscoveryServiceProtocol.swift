//
//  PodcastDiscoveryServiceProtocol.swift
//  Echocast
//
//  Created by OpenAI Assistant on 27/02/25.
//

import Foundation

protocol PodcastDiscoveryServiceProtocol: Sendable {
    func fetchTechnologyPodcasts(limit: Int, offset: Int) async throws -> [DiscoveredPodcast]
}

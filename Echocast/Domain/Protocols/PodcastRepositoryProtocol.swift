//
//  PodcastRepositoryProtocol.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 22/12/25.
//

import Foundation

protocol PodcastRepositoryProtocol: Sendable {
    func upsertPodcast(_ podcast: Podcast) async -> UUID
    func upsertEpisodes(_ items: [EpisodeSyncItem], podcastID: UUID) async
    func fetchPodcast(by feedURL: URL) async -> Podcast?
}

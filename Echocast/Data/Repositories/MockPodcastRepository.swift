//
//  MockPodcastRepository.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 22/12/25.
//

import Foundation

@MainActor
final class MockPodcastRepository: PodcastRepositoryProtocol {
    private var podcastsByID: [UUID: Podcast] = [:]
    private var podcastIDByFeedURL: [String: UUID] = [:]
    private var episodesByPodcastID: [UUID: [String: Episode]] = [:]

    func upsertPodcast(_ podcast: Podcast) async -> UUID {
        let key = podcast.feedURL.absoluteString
        if let existingID = podcastIDByFeedURL[key],
           let existing = podcastsByID[existingID] {
            let updated = Podcast(
                id: existing.id,
                title: podcast.title,
                description: podcast.description,
                author: podcast.author,
                imageURL: podcast.imageURL,
                feedURL: podcast.feedURL,
                episodes: existing.episodes
            )
            podcastsByID[existingID] = updated
            return existingID
        }

        podcastsByID[podcast.id] = podcast
        podcastIDByFeedURL[key] = podcast.id
        episodesByPodcastID[podcast.id] = [:]
        return podcast.id
    }

    func upsertEpisodes(_ items: [EpisodeSyncItem], podcastID: UUID) async {
        guard let podcast = podcastsByID[podcastID] else { return }
        var stored = episodesByPodcastID[podcastID] ?? [:]

        for item in items {
            stored[item.dedupKey] = item.episode
        }

        episodesByPodcastID[podcastID] = stored
        let sorted = stored.values.sorted { lhs, rhs in
            let lhsDate = lhs.publishedAt ?? .distantPast
            let rhsDate = rhs.publishedAt ?? .distantPast
            if lhsDate != rhsDate {
                return lhsDate > rhsDate
            }
            return lhs.title < rhs.title
        }

        podcastsByID[podcastID] = Podcast(
            id: podcast.id,
            title: podcast.title,
            description: podcast.description,
            author: podcast.author,
            imageURL: podcast.imageURL,
            feedURL: podcast.feedURL,
            episodes: sorted
        )
    }

    func fetchPodcast(by feedURL: URL) async -> Podcast? {
        guard let id = podcastIDByFeedURL[feedURL.absoluteString] else { return nil }
        return podcastsByID[id]
    }
}

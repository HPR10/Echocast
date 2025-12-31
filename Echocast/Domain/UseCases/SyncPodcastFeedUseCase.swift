//
//  SyncPodcastFeedUseCase.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 22/12/25.
//

import Foundation

@MainActor
final class SyncPodcastFeedUseCase {
    private let loadPodcastUseCase: LoadPodcastFromRSSUseCase
    private let repository: PodcastRepositoryProtocol

    init(
        loadPodcastUseCase: LoadPodcastFromRSSUseCase,
        repository: PodcastRepositoryProtocol
    ) {
        self.loadPodcastUseCase = loadPodcastUseCase
        self.repository = repository
    }

    func execute(from url: URL) async throws -> Podcast {
        let podcast = try await loadPodcastUseCase.execute(from: url)
        let podcastID = await repository.upsertPodcast(podcast)

        let items = podcast.episodes.map { episode in
            EpisodeSyncItem(episode: episode, dedupKey: dedupKey(for: episode))
        }
        await repository.upsertEpisodes(items, podcastID: podcastID)

        return await repository.fetchPodcast(by: url) ?? podcast
    }

    private func dedupKey(for episode: Episode) -> String {
        if let audioURL = episode.audioURL?.absoluteString, !audioURL.isEmpty {
            return "audio:\(audioURL)"
        }

        if let publishedAt = episode.publishedAt {
            let timestamp = Int(publishedAt.timeIntervalSince1970)
            return "title-date:\(episode.title)|\(timestamp)"
        }

        return "title:\(episode.title)"
    }
}

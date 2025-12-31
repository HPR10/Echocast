//
//  PodcastRepository.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 22/12/25.
//

import Foundation
import SwiftData

@MainActor
final class PodcastRepository: PodcastRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func upsertPodcast(_ podcast: Podcast) async -> UUID {
        let feedURL = podcast.feedURL.absoluteString
        if let entity = fetchPodcastEntity(byFeedURL: feedURL) {
            update(entity: entity, with: podcast)
            entity.lastSyncedAt = .now
            saveContext(action: "upsertPodcast.update")
            return entity.id
        }

        let entity = PodcastEntity(
            id: podcast.id,
            title: podcast.title,
            summary: podcast.description,
            author: podcast.author,
            imageURL: podcast.imageURL?.absoluteString,
            feedURL: feedURL,
            lastSyncedAt: .now
        )
        modelContext.insert(entity)
        saveContext(action: "upsertPodcast.insert")
        return entity.id
    }

    func upsertEpisodes(_ items: [EpisodeSyncItem], podcastID: UUID) async {
        guard let podcast = fetchPodcastEntity(byID: podcastID) else { return }

        for item in items {
            if let existing = fetchEpisodeEntity(podcastID: podcastID, dedupKey: item.dedupKey) {
                update(entity: existing, with: item, podcast: podcast)
            } else {
                let entity = EpisodeEntity(
                    id: item.episode.id,
                    title: item.episode.title,
                    summary: item.episode.description,
                    audioURL: item.episode.audioURL?.absoluteString,
                    duration: item.episode.duration,
                    publishedAt: item.episode.publishedAt,
                    dedupKey: item.dedupKey,
                    podcastID: podcastID,
                    podcast: podcast
                )
                modelContext.insert(entity)
            }
        }

        saveContext(action: "upsertEpisodes")
    }

    func fetchPodcast(by feedURL: URL) async -> Podcast? {
        guard let entity = fetchPodcastEntity(byFeedURL: feedURL.absoluteString) else {
            return nil
        }

        let episodes = fetchEpisodes(for: entity.id)
        let mappedEpisodes = episodes.map(mapEpisode(_:))

        guard let storedFeedURL = URL(string: entity.feedURL) else { return nil }

        return Podcast(
            id: entity.id,
            title: entity.title,
            description: entity.summary,
            author: entity.author,
            imageURL: entity.imageURL.flatMap(URL.init),
            feedURL: storedFeedURL,
            episodes: mappedEpisodes
        )
    }

    // MARK: - Private

    private func update(entity: PodcastEntity, with podcast: Podcast) {
        entity.title = podcast.title
        entity.summary = podcast.description
        entity.author = podcast.author
        entity.imageURL = podcast.imageURL?.absoluteString
        entity.feedURL = podcast.feedURL.absoluteString
    }

    private func update(entity: EpisodeEntity, with item: EpisodeSyncItem, podcast: PodcastEntity) {
        entity.title = item.episode.title
        entity.summary = item.episode.description
        entity.audioURL = item.episode.audioURL?.absoluteString
        entity.duration = item.episode.duration
        entity.publishedAt = item.episode.publishedAt
        entity.dedupKey = item.dedupKey
        entity.podcastID = podcast.id
        entity.podcast = podcast
    }

    private func mapEpisode(_ entity: EpisodeEntity) -> Episode {
        Episode(
            id: entity.id,
            title: entity.title,
            description: entity.summary,
            audioURL: entity.audioURL.flatMap(URL.init),
            duration: entity.duration,
            publishedAt: entity.publishedAt,
            playbackKey: entity.dedupKey
        )
    }

    private func fetchPodcastEntity(byFeedURL feedURL: String) -> PodcastEntity? {
        let descriptor = FetchDescriptor<PodcastEntity>(
            predicate: #Predicate { $0.feedURL == feedURL }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchPodcastEntity(byID id: UUID) -> PodcastEntity? {
        let descriptor = FetchDescriptor<PodcastEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchEpisodeEntity(podcastID: UUID, dedupKey: String) -> EpisodeEntity? {
        let descriptor = FetchDescriptor<EpisodeEntity>(
            predicate: #Predicate { $0.podcastID == podcastID && $0.dedupKey == dedupKey }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchEpisodes(for podcastID: UUID) -> [EpisodeEntity] {
        let descriptor = FetchDescriptor<EpisodeEntity>(
            predicate: #Predicate { $0.podcastID == podcastID },
            sortBy: [
                SortDescriptor(\.publishedAt, order: .reverse),
                SortDescriptor(\.title, order: .forward)
            ]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func saveContext(action: String) {
        do {
            try modelContext.save()
        } catch {
            print("PodcastRepository failed to \(action): \(error)")
        }
    }
}

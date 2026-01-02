//
//  FavoriteEpisodesRepository.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 12/03/25.
//

import Foundation
import SwiftData

@MainActor
final class FavoriteEpisodesRepository: FavoriteEpisodesRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func list() async -> [FavoriteEpisode] {
        let descriptor = FetchDescriptor<FavoriteEpisodeEntity>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        let entities = (try? modelContext.fetch(descriptor)) ?? []
        return entities.map(makeFavoriteEpisode)
    }

    func save(_ episode: FavoriteEpisode) async {
        let entity = fetchEntity(by: episode.playbackKey) ?? FavoriteEpisodeEntity(
            playbackKey: episode.playbackKey,
            title: episode.title,
            podcastTitle: episode.podcastTitle,
            summary: episode.summary,
            audioURL: episode.audioURL?.absoluteString,
            duration: episode.duration,
            publishedAt: episode.publishedAt,
            addedAt: episode.addedAt
        )

        entity.title = episode.title
        entity.podcastTitle = episode.podcastTitle
        entity.summary = episode.summary
        entity.audioURL = episode.audioURL?.absoluteString
        entity.duration = episode.duration
        entity.publishedAt = episode.publishedAt
        entity.addedAt = episode.addedAt

        modelContext.insert(entity)
        saveContext(action: "save")
    }

    func remove(playbackKey: String) async {
        guard let entity = fetchEntity(by: playbackKey) else { return }
        modelContext.delete(entity)
        saveContext(action: "delete")
    }

    func exists(playbackKey: String) async -> Bool {
        fetchEntity(by: playbackKey) != nil
    }

    // MARK: - Private

    private func fetchEntity(by playbackKey: String) -> FavoriteEpisodeEntity? {
        let descriptor = FetchDescriptor<FavoriteEpisodeEntity>(
            predicate: #Predicate { $0.playbackKey == playbackKey }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func makeFavoriteEpisode(from entity: FavoriteEpisodeEntity) -> FavoriteEpisode {
        FavoriteEpisode(
            playbackKey: entity.playbackKey,
            title: entity.title,
            podcastTitle: entity.podcastTitle,
            summary: entity.summary,
            audioURL: entity.audioURL.flatMap(URL.init(string:)),
            duration: entity.duration,
            publishedAt: entity.publishedAt,
            addedAt: entity.addedAt
        )
    }

    private func saveContext(action: String) {
        do {
            try modelContext.save()
        } catch {
            print("FavoriteEpisodesRepository failed to \(action): \(error)")
        }
    }
}

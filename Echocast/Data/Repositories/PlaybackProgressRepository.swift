//
//  PlaybackProgressRepository.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 22/12/25.
//

import Foundation
import SwiftData

@MainActor
final class PlaybackProgressRepository: PlaybackProgressRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ progress: PlaybackProgress) async {
        guard let entity = fetchEpisodeEntity(by: progress.key) else { return }
        entity.playbackPosition = progress.position
        entity.playbackUpdatedAt = progress.updatedAt
        saveContext(action: "save")
    }

    func fetch(for key: String) async -> PlaybackProgress? {
        guard let entity = fetchEpisodeEntity(by: key) else { return nil }
        let position = entity.playbackPosition
        guard position > 0 else { return nil }
        return PlaybackProgress(
            key: key,
            position: position,
            duration: entity.duration,
            updatedAt: entity.playbackUpdatedAt ?? .now
        )
    }

    func clear(for key: String) async {
        guard let entity = fetchEpisodeEntity(by: key) else { return }
        entity.playbackPosition = 0
        entity.playbackUpdatedAt = nil
        saveContext(action: "clear")
    }

    // MARK: - Private

    private func fetchEpisodeEntity(by dedupKey: String) -> EpisodeEntity? {
        let descriptor = FetchDescriptor<EpisodeEntity>(
            predicate: #Predicate { $0.dedupKey == dedupKey }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func saveContext(action: String) {
        do {
            try modelContext.save()
        } catch {
            print("PlaybackProgressRepository failed to \(action): \(error)")
        }
    }
}

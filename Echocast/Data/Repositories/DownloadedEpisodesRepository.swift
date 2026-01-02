//
//  DownloadedEpisodesRepository.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import Foundation
import SwiftData

@MainActor
final class DownloadedEpisodesRepository: DownloadedEpisodesRepositoryProtocol {
    private let modelContext: ModelContext
    private let timeToLive: TimeInterval
    private let fileProvider: DownloadedFileProvider

    init(
        modelContext: ModelContext,
        timeToLive: TimeInterval = 30 * 24 * 60 * 60,
        fileProvider: DownloadedFileProvider
    ) {
        self.modelContext = modelContext
        self.timeToLive = timeToLive
        self.fileProvider = fileProvider
    }

    func fetch(playbackKey: String) async -> DownloadedEpisode? {
        guard let entity = fetchEntity(playbackKey: playbackKey) else { return nil }
        guard fileProvider.fileExists(at: URL(fileURLWithPath: entity.localFilePath)) else {
            modelContext.delete(entity)
            saveContext(action: "deleteMissingDownload")
            return nil
        }
        return map(entity)
    }

    func fetchAll() async -> [DownloadedEpisode] {
        let descriptor = FetchDescriptor<DownloadedEpisodeEntity>(
            sortBy: [
                SortDescriptor(\.downloadedAt, order: .reverse),
                SortDescriptor(\.title, order: .forward)
            ]
        )
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let validItems = filterValidEntities(from: items, action: "deleteMissingDownloads")
        return validItems.map(map)
    }

    func save(_ episode: DownloadedEpisode) async {
        if let existing = fetchEntity(playbackKey: episode.playbackKey) {
            update(entity: existing, with: episode)
        } else {
            modelContext.insert(makeEntity(from: episode))
        }
        saveContext(action: "saveDownloadedEpisode")
    }

    func delete(playbackKey: String) async {
        guard let entity = fetchEntity(playbackKey: playbackKey) else { return }
        fileProvider.removeFile(at: URL(fileURLWithPath: entity.localFilePath))
        modelContext.delete(entity)
        saveContext(action: "deleteDownloadedEpisode")
    }

    func deleteExpired(before date: Date) async {
        let cutoffDate = date.addingTimeInterval(-timeToLive)
        let descriptor = FetchDescriptor<DownloadedEpisodeEntity>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let expired = items.filter { entity in
            if let expiresAt = entity.expiresAt {
                return expiresAt <= date
            }
            return entity.downloadedAt <= cutoffDate
        }
        expired.forEach {
            fileProvider.removeFile(at: URL(fileURLWithPath: $0.localFilePath))
            modelContext.delete($0)
        }
        if !expired.isEmpty {
            saveContext(action: "deleteExpiredDownloads")
        }
    }

    func totalSizeInBytes() async -> Int64 {
        let descriptor = FetchDescriptor<DownloadedEpisodeEntity>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let validItems = filterValidEntities(from: items, action: "deleteMissingDownloads")
        return validItems.reduce(0) { $0 + $1.fileSize }
    }

    // MARK: - Private

    private func fetchEntity(playbackKey: String) -> DownloadedEpisodeEntity? {
        let descriptor = FetchDescriptor<DownloadedEpisodeEntity>(
            predicate: #Predicate { $0.playbackKey == playbackKey }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func makeEntity(from model: DownloadedEpisode) -> DownloadedEpisodeEntity {
        DownloadedEpisodeEntity(
            playbackKey: model.playbackKey,
            title: model.title,
            podcastTitle: model.podcastTitle,
            audioURL: model.audioURL.absoluteString,
            localFilePath: model.localFileURL.path,
            fileSize: model.fileSize,
            downloadedAt: model.downloadedAt,
            expiresAt: model.expiresAt
        )
    }

    private func update(entity: DownloadedEpisodeEntity, with model: DownloadedEpisode) {
        entity.playbackKey = model.playbackKey
        entity.title = model.title
        entity.podcastTitle = model.podcastTitle
        entity.audioURL = model.audioURL.absoluteString
        entity.localFilePath = model.localFileURL.path
        entity.fileSize = model.fileSize
        entity.downloadedAt = model.downloadedAt
        entity.expiresAt = model.expiresAt
    }

    private func map(_ entity: DownloadedEpisodeEntity) -> DownloadedEpisode {
        DownloadedEpisode(
            playbackKey: entity.playbackKey,
            title: entity.title,
            podcastTitle: entity.podcastTitle,
            audioURL: URL(string: entity.audioURL) ?? URL(fileURLWithPath: entity.audioURL),
            localFileURL: URL(fileURLWithPath: entity.localFilePath),
            fileSize: entity.fileSize,
            downloadedAt: entity.downloadedAt,
            expiresAt: entity.expiresAt
        )
    }

    private func filterValidEntities(
        from items: [DownloadedEpisodeEntity],
        action: String
    ) -> [DownloadedEpisodeEntity] {
        var validItems: [DownloadedEpisodeEntity] = []
        var removedAny = false

        for item in items {
            if fileProvider.fileExists(at: URL(fileURLWithPath: item.localFilePath)) {
                validItems.append(item)
            } else {
                modelContext.delete(item)
                removedAny = true
            }
        }

        if removedAny {
            saveContext(action: action)
        }

        return validItems
    }

    private func saveContext(action: String) {
        do {
            try modelContext.save()
        } catch {
            print("DownloadedEpisodesRepository failed to \(action): \(error)")
        }
    }
}

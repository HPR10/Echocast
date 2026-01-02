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
        guard let localURL = resolveLocalURL(for: entity) else {
            modelContext.delete(entity)
            saveContext(action: "deleteMissingDownload")
            return nil
        }
        return map(entity, localFileURL: localURL)
    }

    func fetchAll() async -> [DownloadedEpisode] {
        let descriptor = FetchDescriptor<DownloadedEpisodeEntity>(
            sortBy: [
                SortDescriptor(\.downloadedAt, order: .reverse),
                SortDescriptor(\.title, order: .forward)
            ]
        )
        let items = (try? modelContext.fetch(descriptor)) ?? []
        var removedAny = false

        let mapped: [DownloadedEpisode] = items.compactMap { entity in
            guard let localURL = resolveLocalURL(for: entity) else {
                modelContext.delete(entity)
                removedAny = true
                return nil
            }
            return map(entity, localFileURL: localURL)
        }

        if removedAny {
            saveContext(action: "deleteMissingDownloads")
        }

        return mapped
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
        var removedAny = false
        var total: Int64 = 0

        for item in items {
            guard let localURL = resolveLocalURL(for: item) else {
                modelContext.delete(item)
                removedAny = true
                continue
            }
            total += fileProvider.fileSize(at: localURL) ?? item.fileSize
        }

        if removedAny {
            saveContext(action: "deleteMissingDownloads")
        }

        return total
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

    private func map(
        _ entity: DownloadedEpisodeEntity,
        localFileURL: URL
    ) -> DownloadedEpisode {
        DownloadedEpisode(
            playbackKey: entity.playbackKey,
            title: entity.title,
            podcastTitle: entity.podcastTitle,
            audioURL: URL(string: entity.audioURL) ?? URL(fileURLWithPath: entity.audioURL),
            localFileURL: localFileURL,
            fileSize: entity.fileSize,
            downloadedAt: entity.downloadedAt,
            expiresAt: entity.expiresAt
        )
    }

    private func resolveLocalURL(for entity: DownloadedEpisodeEntity) -> URL? {
        let storedURL = URL(fileURLWithPath: entity.localFilePath)
        if fileProvider.fileExists(at: storedURL) {
            return storedURL
        }

        let extensionFromStored = storedURL.pathExtension
        let extensionFromRemote = URL(string: entity.audioURL)?.pathExtension
        let resolvedExtension = [extensionFromStored, extensionFromRemote]
            .compactMap { $0 }
            .first { !$0.isEmpty }

        let expectedURL = fileProvider.localURL(
            for: entity.playbackKey,
            fileExtension: resolvedExtension
        )

        if fileProvider.fileExists(at: expectedURL) {
            if expectedURL.path != entity.localFilePath {
                entity.localFilePath = expectedURL.path
                saveContext(action: "updateLocalFilePath")
            }
            return expectedURL
        }

        return nil
    }

    private func saveContext(action: String) {
        do {
            try modelContext.save()
        } catch {
            print("DownloadedEpisodesRepository failed to \(action): \(error)")
        }
    }
}

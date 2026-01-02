//
//  EnqueueEpisodeDownloadUseCase.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import Foundation

@MainActor
final class EnqueueEpisodeDownloadUseCase {
    private let downloadService: EpisodeDownloadServiceProtocol
    private let repository: DownloadedEpisodesRepositoryProtocol
    private let maxCacheSizeInBytes: Int64
    private let timeToLive: TimeInterval

    init(
        downloadService: EpisodeDownloadServiceProtocol,
        repository: DownloadedEpisodesRepositoryProtocol,
        maxCacheSizeInBytes: Int64 = 1_000_000_000,
        timeToLive: TimeInterval = 30 * 24 * 60 * 60
    ) {
        self.downloadService = downloadService
        self.repository = repository
        self.maxCacheSizeInBytes = maxCacheSizeInBytes
        self.timeToLive = timeToLive
    }

    func execute(_ request: EpisodeDownloadRequest) async throws {
        guard request.episode.audioURL != nil else {
            throw DownloadError.missingAudioURL
        }

        let now = Date()
        await repository.deleteExpired(before: now)

        if let existing = await repository.fetch(playbackKey: request.episode.playbackKey) {
            if existing.isExpired(referenceDate: now, ttl: timeToLive) {
                await repository.delete(playbackKey: existing.playbackKey)
            } else {
                throw DownloadError.alreadyDownloaded
            }
        }

        if let active = (await downloadService.activeDownloads())
            .first(where: { $0.playbackKey == request.episode.playbackKey }) {
            switch active.state {
            case .queued, .running:
                throw DownloadError.inProgress
            case .finished:
                throw DownloadError.alreadyDownloaded
            case .failed, .cancelled:
                break
            }
        }

        if let estimated = request.expectedSizeInBytes {
            let currentSize = await repository.totalSizeInBytes()
            if currentSize + estimated > maxCacheSizeInBytes {
                throw DownloadError.insufficientSpace
            }
        }

        try await downloadService.enqueue(request)
    }
}

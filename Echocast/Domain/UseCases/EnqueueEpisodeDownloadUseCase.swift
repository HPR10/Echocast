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

    init(
        downloadService: EpisodeDownloadServiceProtocol,
        repository: DownloadedEpisodesRepositoryProtocol,
        maxCacheSizeInBytes: Int64 = 1_000_000_000
    ) {
        self.downloadService = downloadService
        self.repository = repository
        self.maxCacheSizeInBytes = maxCacheSizeInBytes
    }

    func execute(_ request: EpisodeDownloadRequest) async throws {
        guard request.episode.audioURL != nil else {
            throw DownloadError.missingAudioURL
        }

        if await repository.fetch(playbackKey: request.episode.playbackKey) != nil {
            throw DownloadError.alreadyDownloaded
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


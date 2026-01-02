//
//  ResolvePlaybackSourceUseCase.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import Foundation

@MainActor
final class ResolvePlaybackSourceUseCase {
    private let repository: DownloadedEpisodesRepositoryProtocol
    private let timeToLive: TimeInterval

    init(
        repository: DownloadedEpisodesRepositoryProtocol,
        timeToLive: TimeInterval = 30 * 24 * 60 * 60
    ) {
        self.repository = repository
        self.timeToLive = timeToLive
    }

    func execute(for episode: Episode) async throws -> PlaybackSource {
        let now = Date()

        if let downloaded = await repository.fetch(playbackKey: episode.playbackKey) {
            if downloaded.isExpired(referenceDate: now, ttl: timeToLive) {
                await repository.delete(playbackKey: downloaded.playbackKey)
            } else {
                return .local(downloaded.localFileURL)
            }
        }

        guard let remoteURL = episode.audioURL else {
            throw DownloadError.missingAudioURL
        }

        return .remote(remoteURL)
    }
}

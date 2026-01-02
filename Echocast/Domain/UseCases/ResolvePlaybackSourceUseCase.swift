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

    init(
        repository: DownloadedEpisodesRepositoryProtocol
    ) {
        self.repository = repository
    }

    func execute(for episode: Episode) async throws -> PlaybackSource {
        if let downloaded = await repository.fetch(playbackKey: episode.playbackKey) {
            return .local(downloaded.localFileURL)
        }

        guard let remoteURL = episode.audioURL else {
            throw DownloadError.missingAudioURL
        }

        return .remote(remoteURL)
    }
}

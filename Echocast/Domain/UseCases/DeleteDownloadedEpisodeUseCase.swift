//
//  DeleteDownloadedEpisodeUseCase.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import Foundation

@MainActor
final class DeleteDownloadedEpisodeUseCase {
    private let downloadService: EpisodeDownloadServiceProtocol
    private let repository: DownloadedEpisodesRepositoryProtocol

    init(
        downloadService: EpisodeDownloadServiceProtocol,
        repository: DownloadedEpisodesRepositoryProtocol
    ) {
        self.downloadService = downloadService
        self.repository = repository
    }

    func execute(playbackKey: String) async {
        await downloadService.cancelDownload(for: playbackKey)
        await repository.delete(playbackKey: playbackKey)
    }
}

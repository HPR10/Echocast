//
//  ObserveDownloadProgressUseCase.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import Foundation

@MainActor
final class ObserveDownloadProgressUseCase {
    private let downloadService: EpisodeDownloadServiceProtocol

    init(downloadService: EpisodeDownloadServiceProtocol) {
        self.downloadService = downloadService
    }

    func observe() -> AsyncStream<DownloadProgress> {
        downloadService.observeProgress()
    }

    func activeDownloads() async -> [DownloadProgress] {
        await downloadService.activeDownloads()
    }
}

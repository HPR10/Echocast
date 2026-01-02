//
//  EpisodeDownloadServiceProtocol.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import Foundation

protocol EpisodeDownloadServiceProtocol: Sendable {
    func enqueue(_ request: EpisodeDownloadRequest) async throws
    func cancelDownload(for playbackKey: String) async
    func observeProgress() -> AsyncStream<DownloadProgress>
    func activeDownloads() async -> [DownloadProgress]
}

//
//  DownloadsViewModel.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import Foundation
import Observation

@Observable
@MainActor
final class DownloadsViewModel {
    private let listUseCase: ListDownloadedEpisodesUseCase
    private let observeProgressUseCase: ObserveDownloadProgressUseCase
    private let deleteUseCase: DeleteDownloadedEpisodeUseCase
    private let enqueueUseCase: EnqueueEpisodeDownloadUseCase

    private var progressTask: Task<Void, Never>?
    private var inflightMetadata: [String: (title: String, podcastTitle: String)] = [:]

    var downloads: [DownloadedEpisode] = []
    var activeDownloads: [DownloadProgress] = []
    var errorMessage: String?

    init(
        listUseCase: ListDownloadedEpisodesUseCase,
        observeProgressUseCase: ObserveDownloadProgressUseCase,
        deleteUseCase: DeleteDownloadedEpisodeUseCase,
        enqueueUseCase: EnqueueEpisodeDownloadUseCase
    ) {
        self.listUseCase = listUseCase
        self.observeProgressUseCase = observeProgressUseCase
        self.deleteUseCase = deleteUseCase
        self.enqueueUseCase = enqueueUseCase

        startObserving()
        Task { @MainActor in
            await refresh()
            await loadActiveDownloads()
        }
    }

    func refresh() async {
        downloads = await listUseCase.execute()
    }

    func loadActiveDownloads() async {
        activeDownloads = await observeProgressUseCase.activeDownloads()
            .filter { progress in
                switch progress.state {
                case .queued, .running:
                    return true
                case .finished, .failed, .cancelled:
                    return false
                }
            }
    }

    func enqueueDownload(
        for episode: Episode,
        podcastTitle: String,
        podcastImageURL: URL?
    ) async -> String? {
        let request = EpisodeDownloadRequest(
            episode: episode,
            podcastTitle: podcastTitle,
            expectedSizeInBytes: nil,
            podcastImageURL: podcastImageURL
        )
        do {
            inflightMetadata[episode.playbackKey] = (title: episode.title, podcastTitle: podcastTitle)
            try await enqueueUseCase.execute(request)
            errorMessage = nil
            await loadActiveDownloads()
            return nil
        } catch {
            inflightMetadata[episode.playbackKey] = nil
            if let downloadError = error as? DownloadError {
                errorMessage = downloadError.errorDescription
                return downloadError.errorDescription
            }
            errorMessage = error.localizedDescription
            return error.localizedDescription
        }
    }

    func delete(playbackKey: String) async {
        inflightMetadata[playbackKey] = nil
        await deleteUseCase.execute(playbackKey: playbackKey)
        await refresh()
        await loadActiveDownloads()
    }

    func metadata(for playbackKey: String) -> (title: String, podcastTitle: String)? {
        if let meta = inflightMetadata[playbackKey] {
            return meta
        }
        if let downloaded = downloads.first(where: { $0.playbackKey == playbackKey }) {
            return (downloaded.title, downloaded.podcastTitle)
        }
        return nil
    }

    // MARK: - Private

    private func startObserving() {
        progressTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for await progress in observeProgressUseCase.observe() {
                activeDownloads.removeAll { $0.playbackKey == progress.playbackKey }

                switch progress.state {
                case .queued, .running:
                    activeDownloads.append(progress)
                case .finished:
                    inflightMetadata[progress.playbackKey] = nil
                    await refresh()
                    await loadActiveDownloads()
                case .failed(let message):
                    inflightMetadata[progress.playbackKey] = nil
                    errorMessage = message
                    await refresh()
                    await loadActiveDownloads()
                case .cancelled:
                    inflightMetadata[progress.playbackKey] = nil
                    await refresh()
                    await loadActiveDownloads()
                }
            }
        }
    }
}

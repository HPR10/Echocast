//
//  EpisodeDownloadService.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import Foundation

@MainActor
final class EpisodeDownloadService: NSObject, EpisodeDownloadServiceProtocol {
    private let repository: DownloadedEpisodesRepositoryProtocol
    private let fileProvider: DownloadedFileProvider
    private let maxCacheSizeInBytes: Int64
    private let timeToLive: TimeInterval
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.allowsCellularAccess = true
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    private var queue: [EpisodeDownloadRequest] = []
    private var currentTask: URLSessionDownloadTask?
    private var currentRequest: EpisodeDownloadRequest?
    private var currentExpectedBytes: Int64?
    private var currentBytesDownloaded: Int64 = 0

    private var progressContinuation: AsyncStream<DownloadProgress>.Continuation?
    private var progressStreamID = UUID()
    private var progressState: [String: DownloadProgress] = [:]

    init(
        repository: DownloadedEpisodesRepositoryProtocol,
        fileProvider: DownloadedFileProvider,
        maxCacheSizeInBytes: Int64 = 1_000_000_000,
        timeToLive: TimeInterval = 30 * 24 * 60 * 60
    ) {
        self.repository = repository
        self.fileProvider = fileProvider
        self.maxCacheSizeInBytes = maxCacheSizeInBytes
        self.timeToLive = timeToLive
    }

    func enqueue(_ request: EpisodeDownloadRequest) async throws {
        queue.append(request)
        progressState[request.episode.playbackKey] = DownloadProgress(
            playbackKey: request.episode.playbackKey,
            state: .queued,
            bytesDownloaded: 0,
            bytesExpected: request.expectedSizeInBytes
        )
        yieldProgress()
        startNextIfNeeded()
    }

    func cancelDownload(for playbackKey: String) async {
        if let current = currentRequest, current.episode.playbackKey == playbackKey {
            currentTask?.cancel()
            currentTask = nil
            currentRequest = nil
            currentExpectedBytes = nil
            currentBytesDownloaded = 0
        }

        queue.removeAll { $0.episode.playbackKey == playbackKey }
        progressState[playbackKey] = DownloadProgress(
            playbackKey: playbackKey,
            state: .cancelled,
            bytesDownloaded: 0,
            bytesExpected: nil
        )
        yieldProgress()
        progressState.removeValue(forKey: playbackKey)
        startNextIfNeeded()
    }

    func observeProgress() -> AsyncStream<DownloadProgress> {
        let streamID = UUID()
        progressStreamID = streamID

        return AsyncStream { [weak self] continuation in
            guard let self else { return }
            progressContinuation?.finish()
            progressContinuation = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    guard let self, self.progressStreamID == streamID else { return }
                    self.progressContinuation = nil
                }
            }
            self.progressState.values.forEach { continuation.yield($0) }
        }
    }

    func activeDownloads() async -> [DownloadProgress] {
        Array(progressState.values)
    }

    // MARK: - Private

    private func startNextIfNeeded() {
        guard currentTask == nil, let next = queue.first else { return }
        queue.removeFirst()
        currentRequest = next
        currentExpectedBytes = next.expectedSizeInBytes
        currentBytesDownloaded = 0

        guard let url = next.episode.audioURL else {
            finishCurrent(with: .failed("URL de audio invalida."))
            return
        }

        progressState[next.episode.playbackKey] = DownloadProgress(
            playbackKey: next.episode.playbackKey,
            state: .running,
            bytesDownloaded: 0,
            bytesExpected: currentExpectedBytes
        )
        yieldProgress()

        let task = session.downloadTask(with: url)
        currentTask = task
        task.resume()
    }

    private func finishCurrent(with state: DownloadState, bytesDownloaded: Int64 = 0, bytesExpected: Int64? = nil) {
        guard let request = currentRequest else { return }
        progressState[request.episode.playbackKey] = DownloadProgress(
            playbackKey: request.episode.playbackKey,
            state: state,
            bytesDownloaded: bytesDownloaded,
            bytesExpected: bytesExpected
        )
        yieldProgress()

        switch state {
        case .finished, .failed, .cancelled:
            progressState.removeValue(forKey: request.episode.playbackKey)
        case .queued, .running:
            break
        }

        currentTask = nil
        currentRequest = nil
        currentExpectedBytes = nil
        currentBytesDownloaded = 0

        startNextIfNeeded()
    }

    private func yieldProgress() {
        guard let continuation = progressContinuation else { return }
        for progress in progressState.values {
            continuation.yield(progress)
        }
    }

    private nonisolated static func moveDownloadedFile(
        from location: URL,
        to targetURL: URL
    ) -> Result<Int64, DownloadError> {
        try? FileManager.default.removeItem(at: targetURL)
        do {
            try FileManager.default.moveItem(at: location, to: targetURL)
        } catch {
            return .failure(.failed("Falha ao salvar arquivo local."))
        }

        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableURL = targetURL
        try? mutableURL.setResourceValues(values)

        let fileSize: Int64
        if let attributes = try? FileManager.default.attributesOfItem(atPath: targetURL.path),
           let size = attributes[.size] as? NSNumber {
            fileSize = size.int64Value
        } else {
            fileSize = 0
        }

        return .success(fileSize)
    }
}

// MARK: - URLSessionDownloadDelegate

extension EpisodeDownloadService: URLSessionDownloadDelegate {
    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let request = currentRequest else { return }
            currentBytesDownloaded = totalBytesWritten
            if totalBytesExpectedToWrite > 0 {
                currentExpectedBytes = totalBytesExpectedToWrite
            }
            progressState[request.episode.playbackKey] = DownloadProgress(
                playbackKey: request.episode.playbackKey,
                state: .running,
                bytesDownloaded: totalBytesWritten,
                bytesExpected: currentExpectedBytes
            )
            yieldProgress()
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let request = currentRequest else { return }
            let playbackKey = request.episode.playbackKey

            let fileExtension = request.episode.audioURL?.pathExtension
            let targetURL = fileProvider.localURL(
                for: playbackKey,
                fileExtension: fileExtension
            )
            let moveResult = await Task.detached(priority: .utility) {
                Self.moveDownloadedFile(
                    from: location,
                    to: targetURL
                )
            }.value

            guard let current = currentRequest, current.episode.playbackKey == playbackKey else {
                fileProvider.removeFile(at: targetURL)
                return
            }

            let fileSize: Int64
            switch moveResult {
            case .success(let movedSize):
                fileSize = movedSize > 0 ? movedSize : currentBytesDownloaded
            case .failure(let error):
                finishCurrent(with: .failed(error.errorDescription ?? "Falha ao salvar arquivo local."))
                return
            }

            let currentTotal = await repository.totalSizeInBytes()
            if currentTotal + fileSize > maxCacheSizeInBytes {
                fileProvider.removeFile(at: targetURL)
                finishCurrent(with: .failed(DownloadError.insufficientSpace.errorDescription ?? "Espaco insuficiente."))
                return
            }

            let expiresAt = Date().addingTimeInterval(timeToLive)
            let downloaded = DownloadedEpisode(
                playbackKey: playbackKey,
                title: request.episode.title,
                podcastTitle: request.podcastTitle,
                audioURL: request.episode.audioURL ?? targetURL,
                localFileURL: targetURL,
                fileSize: fileSize,
                downloadedAt: .now,
                expiresAt: expiresAt
            )
            await repository.save(downloaded)
            finishCurrent(
                with: .finished,
                bytesDownloaded: fileSize,
                bytesExpected: currentExpectedBytes ?? fileSize
            )
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard error != nil else { return }
            let message = (error as NSError?)?.localizedDescription ?? "Falha no download."
            finishCurrent(with: .failed(message), bytesDownloaded: currentBytesDownloaded, bytesExpected: currentExpectedBytes)
        }
    }
}

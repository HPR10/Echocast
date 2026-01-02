//
//  PlayerViewModel.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 21/12/25.
//

import Foundation
import Observation

@Observable
@MainActor
final class PlayerViewModel {
    let episode: Episode
    let podcastTitle: String
    private let manageProgressUseCase: ManagePlaybackProgressUseCase
    private let playerService: AudioPlayerServiceProtocol
    private let resolvePlaybackSourceUseCase: ResolvePlaybackSourceUseCase?
    private var stateTask: Task<Void, Never>?
    private var eventTask: Task<Void, Never>?
    private var pendingResumeTime: TimeInterval?
    private var hasRestoredProgress = false
    private var lastProgressSaveTime: TimeInterval = 0
    private var lastKnownIsPlaying = false
    private var bufferingVisibilityTask: Task<Void, Never>?
    private let progressSaveInterval: TimeInterval = 10
    private let skipForwardInterval: TimeInterval = 15
    private let skipBackwardInterval: TimeInterval = 30
    private let minPlaybackRate: Float = 0.5
    private let maxPlaybackRate: Float = 2.0
    private let bufferingDisplayDelayNanoseconds: UInt64 = 300_000_000

    var isPlaying = false
    var isBuffering = false
    var bufferingMessage: String?
    var errorMessage: String?
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var playbackRate: Float = 1.0
    private var isScrubbing = false
    private var playbackURL: URL?

    var availablePlaybackRates: [Float] {
        [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    }

    var playbackRateText: String {
        String(format: "%.2gx", playbackRate)
    }

    init(
        episode: Episode,
        podcastTitle: String,
        manageProgressUseCase: ManagePlaybackProgressUseCase,
        playerService: AudioPlayerServiceProtocol,
        resolvePlaybackSourceUseCase: ResolvePlaybackSourceUseCase?
    ) {
        self.episode = episode
        self.podcastTitle = podcastTitle
        self.manageProgressUseCase = manageProgressUseCase
        self.playerService = playerService
        self.resolvePlaybackSourceUseCase = resolvePlaybackSourceUseCase
        if let feedDuration = episode.duration, feedDuration > 0 {
            self.duration = feedDuration
        }

        Task { @MainActor in
            await preparePlayback()
            await loadSavedProgress()
        }
        startObserving()
    }

    var hasAudio: Bool {
        playbackURL != nil
    }

    var isSeekable: Bool {
        duration > 0 && duration.isFinite
    }

    var currentTimeText: String {
        formatTime(currentTime)
    }

    var durationText: String {
        formatTime(duration)
    }

    func togglePlayback() {
        guard hasAudio else {
            errorMessage = "Audio indisponivel para este episodio."
            return
        }

        errorMessage = nil
        if isPlaying {
            playerService.pause()
            saveProgress(force: true)
        } else {
            playerService.play()
        }
    }

    func setPlaybackRate(_ rate: Float) {
        let clamped = max(minPlaybackRate, min(rate, maxPlaybackRate))
        playbackRate = clamped
        playerService.setRate(clamped)
    }

    func skipForward() {
        seek(to: currentTime + skipForwardInterval)
    }

    func skipBackward() {
        seek(to: currentTime - skipBackwardInterval)
    }

    func beginScrubbing() {
        isScrubbing = true
    }

    func endScrubbing(at time: TimeInterval) {
        isScrubbing = false
        seek(to: time)
        saveProgress(force: true)
    }

    func stop() {
        playerService.pause()
        saveProgress(force: true)
    }

    func teardown() {
        stop()
        saveProgress(force: true)
        stateTask?.cancel()
        stateTask = nil
        eventTask?.cancel()
        eventTask = nil
        bufferingVisibilityTask?.cancel()
        bufferingVisibilityTask = nil
        playerService.teardown()
    }

    // MARK: - Private

    private func startObserving() {
        stateTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for await state in playerService.observeState() {
                self.applyState(state)
            }
        }

        eventTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for await event in playerService.observeEvents() {
                self.applyEvent(event)
            }
        }
    }

    private func applyState(_ state: PlayerState) {
        if !isScrubbing {
            currentTime = state.currentTime
        }

        if state.duration > 0 && state.duration.isFinite {
            duration = state.duration
        }

        isPlaying = state.isPlaying
        updateBufferingUI(isBuffering: state.isBuffering, reason: state.bufferingReason)
        playbackRate = state.playbackRate

        restoreProgressIfNeeded()

        if lastKnownIsPlaying && !state.isPlaying {
            saveProgress(force: true)
        } else {
            saveProgress()
        }

        lastKnownIsPlaying = state.isPlaying
    }

    private func applyEvent(_ event: PlayerEvent) {
        switch event {
        case .didFinish:
            Task { @MainActor in
                await clearProgress()
            }
            isBuffering = false
            bufferingMessage = nil
        case .didFail(let error):
            errorMessage = error.errorDescription
            isBuffering = false
            bufferingMessage = nil
        }
    }

    private func makeBufferingMessage(from reason: PlayerBufferingReason?) -> String {
        guard let reason else {
            return "Carregando..."
        }

        switch reason {
        case .insufficientBuffer:
            return "Carregando para continuar a reproducao..."
        case .minimizeStalls:
            return "Carregando para evitar interrupcoes..."
        case .evaluatingBufferingRate:
            return "Avaliando velocidade da conexao..."
        case .noItem:
            return "Preparando o episodio..."
        case .noNetwork:
            return "Sem internet. Aguardando reconexao..."
        case .stalled:
            return "Reproducao interrompida, tentando retomar..."
        case .unknown:
            return "Carregando..."
        }
    }

    private func loadSavedProgress() async {
        guard let progress = await manageProgressUseCase.load(for: episode.playbackKey) else { return }
        pendingResumeTime = progress.position
        restoreProgressIfNeeded()
    }

    private func restoreProgressIfNeeded() {
        guard !hasRestoredProgress else { return }
        guard let pendingResumeTime, pendingResumeTime > 0 else { return }
        guard duration > 0 && duration.isFinite else { return }

        let clamped = max(0, min(pendingResumeTime, duration))
        if clamped > 0 {
            seek(to: clamped)
        }

        hasRestoredProgress = true
        self.pendingResumeTime = nil
    }

    private func saveProgress(force: Bool = false) {
        guard hasAudio else { return }
        guard !isScrubbing || force else { return }

        let now = Date().timeIntervalSince1970
        if !force, now - lastProgressSaveTime < progressSaveInterval {
            return
        }

        guard currentTime > 0 else { return }
        lastProgressSaveTime = now

        let progressDuration = duration > 0 && duration.isFinite ? duration : nil
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.manageProgressUseCase.save(
                for: self.episode.playbackKey,
                position: self.currentTime,
                duration: progressDuration
            )
        }
    }

    private func clearProgress() async {
        await manageProgressUseCase.clear(for: episode.playbackKey)
    }

    private func preparePlayback() async {
        let source: PlaybackSource
        if let resolver = resolvePlaybackSourceUseCase {
            do {
                source = try await resolver.execute(for: episode)
            } catch {
                errorMessage = (error as? DownloadError)?.errorDescription ?? error.localizedDescription
                return
            }
        } else if let url = episode.audioURL {
            source = .remote(url)
        } else {
            errorMessage = DownloadError.missingAudioURL.errorDescription
            return
        }

        playbackURL = source.url
        let resolvedEpisode = Episode(
            id: episode.id,
            title: episode.title,
            description: episode.description,
            audioURL: playbackURL,
            duration: episode.duration,
            publishedAt: episode.publishedAt,
            playbackKey: episode.playbackKey
        )
        playerService.load(episode: resolvedEpisode, podcastTitle: podcastTitle)
    }

    private func updateBufferingUI(isBuffering: Bool, reason: PlayerBufferingReason?) {
        bufferingVisibilityTask?.cancel()

        guard isBuffering else {
            bufferingVisibilityTask = nil
            self.isBuffering = false
            bufferingMessage = nil
            return
        }

        let message = makeBufferingMessage(from: reason)
        if shouldShowBufferingImmediately(reason: reason) {
            self.isBuffering = true
            bufferingMessage = message
            return
        }

        bufferingVisibilityTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            try? await Task.sleep(nanoseconds: bufferingDisplayDelayNanoseconds)
            guard !Task.isCancelled else { return }
            self.isBuffering = true
            self.bufferingMessage = message
        }
    }

    private func shouldShowBufferingImmediately(reason: PlayerBufferingReason?) -> Bool {
        guard let reason else { return false }
        switch reason {
        case .noNetwork, .insufficientBuffer, .stalled:
            return true
        case .minimizeStalls, .evaluatingBufferingRate, .noItem, .unknown:
            return false
        }
    }

    private func seek(to time: TimeInterval) {
        let maxDuration = duration > 0 && duration.isFinite ? duration : time
        let clamped = max(0, min(time, maxDuration))
        currentTime = clamped
        playerService.seek(to: clamped)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let value = seconds.isFinite ? max(seconds, 0) : 0
        return Self.timeFormatter.string(from: value) ?? "0:00"
    }

    private static let timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        formatter.unitsStyle = .positional
        return formatter
    }()
}

@Observable
@MainActor
final class PlayerCoordinator {
    private let manageProgressUseCase: ManagePlaybackProgressUseCase
    private let playerService: AudioPlayerServiceProtocol
    private let resolvePlaybackSourceUseCase: ResolvePlaybackSourceUseCase?
    private(set) var viewModel: PlayerViewModel?

    init(
        manageProgressUseCase: ManagePlaybackProgressUseCase,
        playerService: AudioPlayerServiceProtocol,
        resolvePlaybackSourceUseCase: ResolvePlaybackSourceUseCase?
    ) {
        self.manageProgressUseCase = manageProgressUseCase
        self.playerService = playerService
        self.resolvePlaybackSourceUseCase = resolvePlaybackSourceUseCase
    }

    func prepare(episode: Episode, podcastTitle: String) -> PlayerViewModel {
        if let viewModel, viewModel.episode.playbackKey == episode.playbackKey {
            return viewModel
        }

        viewModel?.teardown()
        let nextViewModel = PlayerViewModel(
            episode: episode,
            podcastTitle: podcastTitle,
            manageProgressUseCase: manageProgressUseCase,
            playerService: playerService,
            resolvePlaybackSourceUseCase: resolvePlaybackSourceUseCase
        )
        viewModel = nextViewModel
        return nextViewModel
    }

    func stopPlayback() {
        viewModel?.teardown()
        viewModel = nil
    }

    func handleViewDisappear(for episode: Episode) {
        guard let viewModel, viewModel.episode.playbackKey == episode.playbackKey else { return }
        guard !viewModel.isPlaying, !viewModel.isBuffering else { return }
        viewModel.teardown()
        self.viewModel = nil
    }
}

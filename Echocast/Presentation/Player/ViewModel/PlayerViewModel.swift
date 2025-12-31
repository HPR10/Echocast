//
//  PlayerViewModel.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 21/12/25.
//

import AVFoundation
import Foundation
import MediaPlayer
import Observation

@Observable
@MainActor
final class PlayerViewModel {
    let episode: Episode
    let podcastTitle: String
    private let manageProgressUseCase: ManagePlaybackProgressUseCase
    private let player: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var itemStatusObserver: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?
    private var failObserver: NSObjectProtocol?
    private var interruptionObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private let remoteCommandCenter = MPRemoteCommandCenter.shared()
    private var playCommandTarget: Any?
    private var pauseCommandTarget: Any?
    private var toggleCommandTarget: Any?
    private var changePlaybackPositionTarget: Any?
    private var wasPlayingBeforeInterruption = false
    private var pendingResumeTime: TimeInterval?
    private var hasRestoredProgress = false
    private var lastProgressSaveTime: TimeInterval = 0
    private let progressSaveInterval: TimeInterval = 10

    var isPlaying = false
    var errorMessage: String?
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    private var isScrubbing = false

    init(
        episode: Episode,
        podcastTitle: String,
        manageProgressUseCase: ManagePlaybackProgressUseCase
    ) {
        self.episode = episode
        self.podcastTitle = podcastTitle
        self.manageProgressUseCase = manageProgressUseCase
        let player = episode.audioURL.map { url in
            AVPlayer(playerItem: AVPlayerItem(url: url))
        }
        self.player = player

        if let player {
            configureAudioSession()
            setupObservers(for: player)
            configureNowPlayingInfo()
            setupRemoteCommands()
            setupAudioSessionObservers()
        }

        Task { @MainActor in
            await loadSavedProgress()
        }
    }

    var hasAudio: Bool {
        episode.audioURL != nil
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
        guard player != nil else {
            errorMessage = "Audio indisponivel para este episodio."
            return
        }

        errorMessage = nil
        if isPlaying {
            pausePlayback()
        } else {
            startPlayback()
        }
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
        pausePlayback()
    }

    func teardown() {
        stop()
        saveProgress(force: true)
        teardownRemoteCommands()
        clearNowPlayingInfo()
        teardownAudioSessionObservers()
        deactivateAudioSession()

        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        statusObserver = nil
        itemStatusObserver = nil

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }

        if let failObserver {
            NotificationCenter.default.removeObserver(failObserver)
            self.failObserver = nil
        }
    }

    // MARK: - Private

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.allowAirPlay, .allowBluetoothHFP])
            try session.setActive(true)
        } catch {
            errorMessage = "Falha ao configurar audio."
        }
    }

    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            return
        }
    }

    private func setupObservers(for player: AVPlayer) {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if !self.isScrubbing {
                    self.currentTime = time.seconds
                }

                if let currentItem = self.player?.currentItem {
                    let duration = currentItem.duration.seconds
                    if duration.isFinite {
                        self.duration = duration
                    }
                }
                self.restoreProgressIfNeeded()
                self.saveProgress()
                self.updateNowPlayingInfo()
            }
        }

        statusObserver = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isPlaying = player.timeControlStatus == .playing
                self.updateNowPlayingInfo()
            }
        }

        itemStatusObserver = player.currentItem?.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if item.status == .readyToPlay {
                    let duration = item.duration.seconds
                    if duration.isFinite {
                        self.duration = duration
                    }
                    self.restoreProgressIfNeeded()
                    self.updateNowPlayingInfo()
                }
                if item.status == .failed {
                    self.errorMessage = item.error?.localizedDescription ?? "Falha ao reproduzir audio."
                    self.isPlaying = false
                    self.updateNowPlayingInfo()
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isPlaying = false
                self.currentTime = self.duration
                await self.clearProgress()
                self.updateNowPlayingInfo()
            }
        }

        failObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] notification in
            let message = (notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error)?
                .localizedDescription ?? "Falha ao reproduzir audio."
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.errorMessage = message
                self.isPlaying = false
                self.updateNowPlayingInfo()
            }
        }
    }

    private func setupAudioSessionObservers() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            let userInfo = notification.userInfo
            let typeValue = userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let optionsValue = userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            Task { @MainActor [weak self] in
                self?.handleAudioSessionInterruption(typeValue: typeValue, optionsValue: optionsValue)
            }
        }

        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            let userInfo = notification.userInfo
            let reasonValue = userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            Task { @MainActor [weak self] in
                self?.handleAudioSessionRouteChange(reasonValue: reasonValue)
            }
        }
    }

    private func teardownAudioSessionObservers() {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
            self.interruptionObserver = nil
        }
        if let routeChangeObserver {
            NotificationCenter.default.removeObserver(routeChangeObserver)
            self.routeChangeObserver = nil
        }
        wasPlayingBeforeInterruption = false
    }

    private func handleAudioSessionInterruption(typeValue: UInt?, optionsValue: UInt?) {
        guard let typeValue, let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            wasPlayingBeforeInterruption = isPlaying
            pausePlayback()
        case .ended:
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue ?? 0)
            if options.contains(.shouldResume), wasPlayingBeforeInterruption {
                startPlayback()
            }
            wasPlayingBeforeInterruption = false
        @unknown default:
            break
        }
    }

    private func handleAudioSessionRouteChange(reasonValue: UInt?) {
        guard let reasonValue, let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        switch reason {
        case .oldDeviceUnavailable:
            pausePlayback()
        case .newDeviceAvailable,
             .categoryChange,
             .override,
             .wakeFromSleep,
             .noSuitableRouteForCategory,
             .routeConfigurationChange,
             .unknown:
            break
        @unknown default:
            break
        }
    }

    private func configureNowPlayingInfo() {
        updateNowPlayingInfo()
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

    private func updateNowPlayingInfo() {
        guard player != nil else { return }

        var info = nowPlayingInfoCenter.nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyTitle] = episode.title
        info[MPMediaItemPropertyAlbumTitle] = podcastTitle

        if duration > 0 && duration.isFinite {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }

        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0

        nowPlayingInfoCenter.nowPlayingInfo = info
        nowPlayingInfoCenter.playbackState = isPlaying ? .playing : .paused
    }

    private func clearNowPlayingInfo() {
        nowPlayingInfoCenter.nowPlayingInfo = nil
        nowPlayingInfoCenter.playbackState = .stopped
    }

    private func setupRemoteCommands() {
        guard player != nil else { return }

        remoteCommandCenter.playCommand.isEnabled = true
        remoteCommandCenter.pauseCommand.isEnabled = true
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = true

        playCommandTarget = remoteCommandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.startPlayback()
            }
            return .success
        }

        pauseCommandTarget = remoteCommandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pausePlayback()
            }
            return .success
        }

        toggleCommandTarget = remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.togglePlayback()
            }
            return .success
        }

        changePlaybackPositionTarget = remoteCommandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            Task { @MainActor [weak self] in
                self?.seek(to: event.positionTime)
            }
            return .success
        }
    }

    private func teardownRemoteCommands() {
        if let playCommandTarget {
            remoteCommandCenter.playCommand.removeTarget(playCommandTarget)
            self.playCommandTarget = nil
        }
        if let pauseCommandTarget {
            remoteCommandCenter.pauseCommand.removeTarget(pauseCommandTarget)
            self.pauseCommandTarget = nil
        }
        if let toggleCommandTarget {
            remoteCommandCenter.togglePlayPauseCommand.removeTarget(toggleCommandTarget)
            self.toggleCommandTarget = nil
        }
        if let changePlaybackPositionTarget {
            remoteCommandCenter.changePlaybackPositionCommand.removeTarget(changePlaybackPositionTarget)
            self.changePlaybackPositionTarget = nil
        }

        remoteCommandCenter.playCommand.isEnabled = false
        remoteCommandCenter.pauseCommand.isEnabled = false
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = false
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = false
    }

    private func startPlayback() {
        guard player != nil else {
            errorMessage = "Audio indisponivel para este episodio."
            return
        }
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }

    private func pausePlayback() {
        player?.pause()
        isPlaying = false
        saveProgress(force: true)
        updateNowPlayingInfo()
    }

    private func seek(to time: TimeInterval) {
        guard let player else { return }
        let clamped = max(0, min(time, duration))
        let target = CMTime(seconds: clamped, preferredTimescale: 600)
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = clamped
        updateNowPlayingInfo()
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

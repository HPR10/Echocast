//
//  AudioPlayerService.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 23/12/25.
//

import AVFoundation
import MediaPlayer

@MainActor
final class AudioPlayerService: AudioPlayerServiceProtocol {
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private let remoteCommandCenter = MPRemoteCommandCenter.shared()

    private var player: AVPlayer?
    private var currentEpisode: Episode?
    private var podcastTitle: String?

    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var itemStatusObserver: NSKeyValueObservation?
    private var waitingObserver: NSKeyValueObservation?
    private var bufferLikelyToKeepUpObserver: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?
    private var failObserver: NSObjectProtocol?
    private var playbackStalledObserver: NSObjectProtocol?
    private var interruptionObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?
    private var playCommandTarget: Any?
    private var pauseCommandTarget: Any?
    private var toggleCommandTarget: Any?
    private var changePlaybackPositionTarget: Any?
    private var skipForwardCommandTarget: Any?
    private var skipBackwardCommandTarget: Any?
    private var changePlaybackRateTarget: Any?

    private var state = PlayerState.idle
    private var stateContinuation: AsyncStream<PlayerState>.Continuation?
    private var eventContinuation: AsyncStream<PlayerEvent>.Continuation?
    private var stateStreamID = UUID()
    private var eventStreamID = UUID()
    private var wasPlayingBeforeInterruption = false
    private var hasSetupRemoteCommands = false
    private var hasSetupAudioSessionObservers = false

    private let skipForwardInterval: TimeInterval = 15
    private let skipBackwardInterval: TimeInterval = 30
    private let minPlaybackRate: Float = 0.5
    private let maxPlaybackRate: Float = 2.0

    private var availablePlaybackRates: [Float] {
        [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    }

    func observeState() -> AsyncStream<PlayerState> {
        let streamID = UUID()
        stateStreamID = streamID

        return AsyncStream { [weak self] continuation in
            guard let self else { return }
            stateContinuation?.finish()
            stateContinuation = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    guard let self, self.stateStreamID == streamID else { return }
                    self.stateContinuation = nil
                }
            }
            continuation.yield(state)
        }
    }

    func observeEvents() -> AsyncStream<PlayerEvent> {
        let streamID = UUID()
        eventStreamID = streamID

        return AsyncStream { [weak self] continuation in
            guard let self else { return }
            eventContinuation?.finish()
            eventContinuation = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    guard let self, self.eventStreamID == streamID else { return }
                    self.eventContinuation = nil
                }
            }
        }
    }

    func load(episode: Episode, podcastTitle: String) {
        currentEpisode = episode
        self.podcastTitle = podcastTitle
        resetPlayerObservers()
        player?.pause()
        player = nil

        state = PlayerState.idle
        if let duration = episode.duration, duration > 0 {
            state.duration = duration
        }

        guard let url = episode.audioURL else {
            yieldState()
            clearNowPlayingInfo()
            return
        }

        let item = AVPlayerItem(url: url)
        item.audioTimePitchAlgorithm = .timeDomain
        let player = AVPlayer(playerItem: item)
        self.player = player

        setupObservers(for: player)
        setupRemoteCommandsIfNeeded()
        setupAudioSessionObserversIfNeeded()
        yieldState()
    }

    func play() {
        guard player != nil else {
            eventContinuation?.yield(.didFail(.audioUnavailable))
            return
        }
        guard activateAudioSession() else {
            eventContinuation?.yield(.didFail(.audioSessionFailure))
            return
        }
        player?.play()
        player?.rate = state.playbackRate
        updateNowPlayingInfo()
    }

    func pause() {
        player?.pause()
        updateState { state in
            state.isPlaying = false
        }
    }

    func seek(to time: TimeInterval) {
        guard let player else { return }
        let maxDuration = state.duration > 0 && state.duration.isFinite ? state.duration : time
        let clamped = max(0, min(time, maxDuration))
        let target = CMTime(seconds: clamped, preferredTimescale: 600)
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
        if state.isPlaying {
            player.rate = state.playbackRate
        }
        updateState { state in
            state.currentTime = clamped
        }
    }

    func setRate(_ rate: Float) {
        let clamped = max(minPlaybackRate, min(rate, maxPlaybackRate))
        let wasPlaying = state.isPlaying
        updateState { state in
            state.playbackRate = clamped
        }
        if wasPlaying {
            player?.rate = clamped
        }
    }

    func teardown() {
        pause()
        resetPlayerObservers()
        teardownRemoteCommands()
        clearNowPlayingInfo()
        teardownAudioSessionObservers()
        deactivateAudioSession()
        player = nil
        currentEpisode = nil
        podcastTitle = nil
        stateContinuation?.finish()
        stateContinuation = nil
        eventContinuation?.finish()
        eventContinuation = nil
    }

    // MARK: - Private

    private func updateState(_ update: (inout PlayerState) -> Void) {
        update(&state)
        yieldState()
    }

    private func yieldState() {
        stateContinuation?.yield(state)
        updateNowPlayingInfo()
    }

    private func setupObservers(for player: AVPlayer) {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.updateState { state in
                    state.currentTime = time.seconds
                    if let currentItem = self.player?.currentItem {
                        let duration = currentItem.duration.seconds
                        if duration.isFinite {
                            state.duration = duration
                        }
                    }
                }
            }
        }

        statusObserver = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let buffering = self.bufferingState(for: player)
                self.updateState { state in
                    state.isPlaying = player.timeControlStatus == .playing
                    state.isBuffering = buffering.isBuffering
                    state.bufferingReason = buffering.reason
                }
            }
        }

        waitingObserver = player.observe(\.reasonForWaitingToPlay, options: [.initial, .new]) { [weak self] player, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let buffering = self.bufferingState(for: player)
                self.updateState { state in
                    state.isBuffering = buffering.isBuffering
                    state.bufferingReason = buffering.reason
                }
            }
        }

        itemStatusObserver = player.currentItem?.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    let duration = item.duration.seconds
                    if duration.isFinite {
                        self.updateState { state in
                            state.duration = duration
                        }
                    }
                case .failed:
                    let message = item.error?.localizedDescription ?? ""
                    self.eventContinuation?.yield(.didFail(.playbackFailed(message)))
                    self.updateState { state in
                        state.isPlaying = false
                        state.isBuffering = false
                        state.bufferingReason = nil
                    }
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }

        bufferLikelyToKeepUpObserver = player.currentItem?.observe(
            \.isPlaybackLikelyToKeepUp,
            options: [.initial, .new]
        ) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if item.isPlaybackLikelyToKeepUp {
                    self.updateState { state in
                        state.isBuffering = false
                        state.bufferingReason = nil
                    }
                } else {
                    self.updateState { state in
                        state.isBuffering = true
                        state.bufferingReason = .insufficientBuffer
                    }
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
                self.updateState { state in
                    state.isPlaying = false
                    state.currentTime = state.duration
                    state.isBuffering = false
                    state.bufferingReason = nil
                }
                self.eventContinuation?.yield(.didFinish)
            }
        }

        failObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] notification in
            let message = (notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error)?
                .localizedDescription ?? ""
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.eventContinuation?.yield(.didFail(.playbackFailed(message)))
                self.updateState { state in
                    state.isPlaying = false
                    state.isBuffering = false
                    state.bufferingReason = nil
                }
            }
        }

        playbackStalledObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.updateState { state in
                    state.isBuffering = true
                    state.bufferingReason = .stalled
                    state.isPlaying = false
                }
            }
        }
    }

    private func resetPlayerObservers() {
        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        statusObserver = nil
        itemStatusObserver = nil
        waitingObserver = nil
        bufferLikelyToKeepUpObserver = nil

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }

        if let failObserver {
            NotificationCenter.default.removeObserver(failObserver)
            self.failObserver = nil
        }

        if let playbackStalledObserver {
            NotificationCenter.default.removeObserver(playbackStalledObserver)
            self.playbackStalledObserver = nil
        }
    }

    private func bufferingState(for player: AVPlayer) -> (isBuffering: Bool, reason: PlayerBufferingReason?) {
        let status = player.timeControlStatus
        let isWaiting = status == .waitingToPlayAtSpecifiedRate
        let likelyToKeepUp = player.currentItem?.isPlaybackLikelyToKeepUp ?? true

        if isWaiting || !likelyToKeepUp {
            if !likelyToKeepUp {
                return (true, .insufficientBuffer)
            }

            switch player.reasonForWaitingToPlay {
            case .toMinimizeStalls:
                return (true, .minimizeStalls)
            case .evaluatingBufferingRate:
                return (true, .evaluatingBufferingRate)
            case .noItemToPlay:
                return (true, .noItem)
            case .none:
                return (true, .unknown)
            @unknown default:
                return (true, .unknown)
            }
        }

        return (false, nil)
    }

    private func updateNowPlayingInfo() {
        guard let episode = currentEpisode, player != nil else { return }

        var info = nowPlayingInfoCenter.nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyTitle] = episode.title
        info[MPMediaItemPropertyAlbumTitle] = podcastTitle

        if state.duration > 0 && state.duration.isFinite {
            info[MPMediaItemPropertyPlaybackDuration] = state.duration
        }

        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = state.currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = state.isPlaying ? state.playbackRate : 0.0
        info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = state.playbackRate

        nowPlayingInfoCenter.nowPlayingInfo = info
        nowPlayingInfoCenter.playbackState = state.isPlaying ? .playing : .paused
    }

    private func clearNowPlayingInfo() {
        nowPlayingInfoCenter.nowPlayingInfo = nil
        nowPlayingInfoCenter.playbackState = .stopped
    }

    private func setupRemoteCommandsIfNeeded() {
        guard !hasSetupRemoteCommands else { return }
        hasSetupRemoteCommands = true
        setupRemoteCommands()
    }

    private func setupRemoteCommands() {
        remoteCommandCenter.playCommand.isEnabled = true
        remoteCommandCenter.pauseCommand.isEnabled = true
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = true
        remoteCommandCenter.skipForwardCommand.isEnabled = true
        remoteCommandCenter.skipBackwardCommand.isEnabled = true
        remoteCommandCenter.changePlaybackRateCommand.isEnabled = true

        remoteCommandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: skipForwardInterval)]
        remoteCommandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: skipBackwardInterval)]
        remoteCommandCenter.changePlaybackRateCommand.supportedPlaybackRates = availablePlaybackRates
            .map { NSNumber(value: $0) }

        playCommandTarget = remoteCommandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.play()
            }
            return .success
        }

        pauseCommandTarget = remoteCommandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pause()
            }
            return .success
        }

        toggleCommandTarget = remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.state.isPlaying {
                    self.pause()
                } else {
                    self.play()
                }
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

        skipForwardCommandTarget = remoteCommandCenter.skipForwardCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.seek(to: self.state.currentTime + self.skipForwardInterval)
            }
            return .success
        }

        skipBackwardCommandTarget = remoteCommandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.seek(to: self.state.currentTime - self.skipBackwardInterval)
            }
            return .success
        }

        changePlaybackRateTarget = remoteCommandCenter.changePlaybackRateCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackRateCommandEvent else {
                return .commandFailed
            }
            Task { @MainActor [weak self] in
                self?.setRate(event.playbackRate)
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
        if let skipForwardCommandTarget {
            remoteCommandCenter.skipForwardCommand.removeTarget(skipForwardCommandTarget)
            self.skipForwardCommandTarget = nil
        }
        if let skipBackwardCommandTarget {
            remoteCommandCenter.skipBackwardCommand.removeTarget(skipBackwardCommandTarget)
            self.skipBackwardCommandTarget = nil
        }
        if let changePlaybackRateTarget {
            remoteCommandCenter.changePlaybackRateCommand.removeTarget(changePlaybackRateTarget)
            self.changePlaybackRateTarget = nil
        }

        remoteCommandCenter.playCommand.isEnabled = false
        remoteCommandCenter.pauseCommand.isEnabled = false
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = false
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = false
        remoteCommandCenter.skipForwardCommand.isEnabled = false
        remoteCommandCenter.skipBackwardCommand.isEnabled = false
        remoteCommandCenter.changePlaybackRateCommand.isEnabled = false
        hasSetupRemoteCommands = false
    }

    private func setupAudioSessionObserversIfNeeded() {
        guard !hasSetupAudioSessionObservers else { return }
        hasSetupAudioSessionObservers = true
        setupAudioSessionObservers()
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
        hasSetupAudioSessionObservers = false
    }

    private func handleAudioSessionInterruption(typeValue: UInt?, optionsValue: UInt?) {
        guard let typeValue, let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            wasPlayingBeforeInterruption = state.isPlaying
            pause()
        case .ended:
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue ?? 0)
            if options.contains(.shouldResume), wasPlayingBeforeInterruption {
                play()
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
            pause()
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

    @discardableResult
    private func configureAudioSession() -> Bool {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.allowAirPlay, .allowBluetoothA2DP]
            )
            return true
        } catch {
            return false
        }
    }

    private func activateAudioSession() -> Bool {
        guard configureAudioSession() else { return false }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            return true
        } catch {
            return false
        }
    }

    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            return
        }
    }
}

//
//  PlayerViewModel.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 21/12/25.
//

import AVFoundation
import Foundation
import Observation

@Observable
@MainActor
final class PlayerViewModel {
    let episode: Episode
    let podcastTitle: String
    private let player: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var itemStatusObserver: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?
    private var failObserver: NSObjectProtocol?

    var isPlaying = false
    var errorMessage: String?
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    private var isScrubbing = false

    init(episode: Episode, podcastTitle: String) {
        self.episode = episode
        self.podcastTitle = podcastTitle
        let player = episode.audioURL.map { url in
            AVPlayer(playerItem: AVPlayerItem(url: url))
        }
        self.player = player

        if let player {
            configureAudioSession()
            setupObservers(for: player)
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
        guard let player else {
            errorMessage = "Audio indisponivel para este episodio."
            return
        }

        errorMessage = nil
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func beginScrubbing() {
        isScrubbing = true
    }

    func endScrubbing(at time: TimeInterval) {
        isScrubbing = false
        seek(to: time)
    }

    func stop() {
        player?.pause()
        isPlaying = false
    }

    func teardown() {
        stop()

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
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
        } catch {
            errorMessage = "Falha ao configurar audio."
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

                if let duration = self.player?.currentItem?.duration.seconds, duration.isFinite {
                    self.duration = duration
                }
            }
        }

        statusObserver = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isPlaying = player.timeControlStatus == .playing
            }
        }

        itemStatusObserver = player.currentItem?.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if item.status == .failed {
                    self.errorMessage = item.error?.localizedDescription ?? "Falha ao reproduzir audio."
                    self.isPlaying = false
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
            }
        }
    }

    private func seek(to time: TimeInterval) {
        guard let player else { return }
        let clamped = max(0, min(time, duration))
        let target = CMTime(seconds: clamped, preferredTimescale: 600)
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
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

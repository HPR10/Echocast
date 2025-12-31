//
//  MockAudioPlayerService.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 23/12/25.
//

import Foundation

@MainActor
final class MockAudioPlayerService: AudioPlayerServiceProtocol {
    private var state = PlayerState.idle
    private var stateContinuation: AsyncStream<PlayerState>.Continuation?
    private var eventContinuation: AsyncStream<PlayerEvent>.Continuation?
    private var stateStreamID = UUID()
    private var eventStreamID = UUID()

    private let minPlaybackRate: Float = 0.5
    private let maxPlaybackRate: Float = 2.0

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
        state = PlayerState.idle
        if let duration = episode.duration, duration > 0 {
            state.duration = duration
        }
        stateContinuation?.yield(state)
    }

    func play() {
        state.isPlaying = true
        stateContinuation?.yield(state)
    }

    func pause() {
        state.isPlaying = false
        stateContinuation?.yield(state)
    }

    func seek(to time: TimeInterval) {
        let maxDuration = state.duration > 0 && state.duration.isFinite ? state.duration : time
        state.currentTime = max(0, min(time, maxDuration))
        stateContinuation?.yield(state)
    }

    func setRate(_ rate: Float) {
        state.playbackRate = max(minPlaybackRate, min(rate, maxPlaybackRate))
        stateContinuation?.yield(state)
    }

    func teardown() {
        stateContinuation?.finish()
        stateContinuation = nil
        eventContinuation?.finish()
        eventContinuation = nil
    }
}

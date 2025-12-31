//
//  AudioPlayerServiceProtocol.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 23/12/25.
//

import Foundation

@MainActor
protocol AudioPlayerServiceProtocol {
    func observeState() -> AsyncStream<PlayerState>
    func observeEvents() -> AsyncStream<PlayerEvent>
    func load(episode: Episode, podcastTitle: String)
    func play()
    func pause()
    func seek(to time: TimeInterval)
    func setRate(_ rate: Float)
    func teardown()
}

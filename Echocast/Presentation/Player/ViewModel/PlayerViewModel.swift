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

    var isPlaying = false
    var errorMessage: String?

    init(episode: Episode, podcastTitle: String) {
        self.episode = episode
        self.podcastTitle = podcastTitle
        if let url = episode.audioURL {
            self.player = AVPlayer(url: url)
        } else {
            self.player = nil
        }
    }

    var hasAudio: Bool {
        episode.audioURL != nil
    }

    func togglePlayback() {
        guard let player else {
            errorMessage = "Audio indisponivel para este episodio."
            return
        }

        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func stop() {
        player?.pause()
        isPlaying = false
    }
}

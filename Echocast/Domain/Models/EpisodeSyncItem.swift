//
//  EpisodeSyncItem.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 22/12/25.
//

import Foundation

struct EpisodeSyncItem: Sendable {
    let episode: Episode
    let dedupKey: String

    init(episode: Episode, dedupKey: String) {
        self.episode = episode
        self.dedupKey = dedupKey
    }
}

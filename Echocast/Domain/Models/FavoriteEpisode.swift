//
//  FavoriteEpisode.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 12/03/25.
//

import Foundation

struct FavoriteEpisode: Identifiable, Hashable, Sendable {
    var id: String { playbackKey }

    let playbackKey: String
    let title: String
    let podcastTitle: String
    let podcastImageURL: URL?
    let summary: String?
    let audioURL: URL?
    let duration: TimeInterval?
    let publishedAt: Date?
    let addedAt: Date

    var episode: Episode {
        Episode(
            title: title,
            description: summary,
            audioURL: audioURL,
            duration: duration,
            publishedAt: publishedAt,
            playbackKey: playbackKey
        )
    }
}

//
//  FavoriteEpisodeEntity.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 12/03/25.
//

import Foundation
import SwiftData

@Model
final class FavoriteEpisodeEntity {
    @Attribute(.unique) var playbackKey: String
    var title: String
    var podcastTitle: String
    var summary: String?
    var audioURL: String?
    var duration: TimeInterval?
    var publishedAt: Date?
    var addedAt: Date

    init(
        playbackKey: String,
        title: String,
        podcastTitle: String,
        summary: String?,
        audioURL: String?,
        duration: TimeInterval?,
        publishedAt: Date?,
        addedAt: Date
    ) {
        self.playbackKey = playbackKey
        self.title = title
        self.podcastTitle = podcastTitle
        self.summary = summary
        self.audioURL = audioURL
        self.duration = duration
        self.publishedAt = publishedAt
        self.addedAt = addedAt
    }
}

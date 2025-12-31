//
//  PodcastEntity.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 22/12/25.
//

import Foundation
import SwiftData

@Model
final class PodcastEntity {
    var id: UUID
    var title: String
    var summary: String?
    var author: String?
    var imageURL: String?
    var feedURL: String
    var lastSyncedAt: Date

    @Relationship(deleteRule: .cascade)
    var episodes: [EpisodeEntity]

    init(
        id: UUID = UUID(),
        title: String,
        summary: String? = nil,
        author: String? = nil,
        imageURL: String? = nil,
        feedURL: String,
        lastSyncedAt: Date = .now,
        episodes: [EpisodeEntity] = []
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.author = author
        self.imageURL = imageURL
        self.feedURL = feedURL
        self.lastSyncedAt = lastSyncedAt
        self.episodes = episodes
    }
}

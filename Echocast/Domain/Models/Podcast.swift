//
//  Podcast.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 20/12/25.
//

import Foundation

struct Podcast: Sendable, Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let author: String?
    let imageURL: URL?
    let feedURL: URL
    let episodes: [Episode]

    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        author: String? = nil,
        imageURL: URL? = nil,
        feedURL: URL,
        episodes: [Episode] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.author = author
        self.imageURL = imageURL
        self.feedURL = feedURL
        self.episodes = episodes
    }
}

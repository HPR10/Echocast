//
//  Episode.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 20/12/25.
//

import Foundation

struct Episode: Sendable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let description: String?
    let audioURL: URL?
    let duration: TimeInterval?
    let publishedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        audioURL: URL? = nil,
        duration: TimeInterval? = nil,
        publishedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.audioURL = audioURL
        self.duration = duration
        self.publishedAt = publishedAt
    }
}

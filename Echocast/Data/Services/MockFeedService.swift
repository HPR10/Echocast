//
//  MockFeedService.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 20/12/25.
//

import Foundation

final class MockFeedService: FeedServiceProtocol {
    var mockPodcast: Podcast?
    var mockError: FeedError?
    var delay: TimeInterval

    init(
        mockPodcast: Podcast? = nil,
        mockError: FeedError? = nil,
        delay: TimeInterval = 0.5
    ) {
        self.mockPodcast = mockPodcast
        self.mockError = mockError
        self.delay = delay
    }

    func fetchFeed(from url: URL) async throws -> Podcast {
        if delay > 0 {
            try await Task.sleep(for: .seconds(delay))
        }

        if let error = mockError {
            throw error
        }

        if let podcast = mockPodcast {
            return podcast
        }

        return Podcast(
            title: "Podcast de Teste",
            description: "Descricao do podcast de teste para preview e testes unitarios.",
            author: "Autor Teste",
            feedURL: url,
            episodes: [
                Episode(
                    title: "Episodio 1: Introducao",
                    description: "Primeiro episodio do podcast",
                    duration: 1800,
                    publishedAt: Date()
                ),
                Episode(
                    title: "Episodio 2: Desenvolvimento",
                    description: "Segundo episodio do podcast",
                    duration: 2400,
                    publishedAt: Date().addingTimeInterval(-86400)
                )
            ]
        )
    }

    func clearCache() async {}
}

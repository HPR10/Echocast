//
//  ManageFavoriteEpisodesUseCase.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 12/03/25.
//

import Foundation

@MainActor
final class ManageFavoriteEpisodesUseCase {
    private let repository: FavoriteEpisodesRepositoryProtocol

    init(repository: FavoriteEpisodesRepositoryProtocol) {
        self.repository = repository
    }

    func list() async -> [FavoriteEpisode] {
        await repository.list()
    }

    func isFavorite(playbackKey: String) async -> Bool {
        await repository.exists(playbackKey: playbackKey)
    }

    func add(episode: Episode, podcastTitle: String, podcastImageURL: URL?) async {
        let favorite = makeFavoriteEpisode(
            from: episode,
            podcastTitle: podcastTitle,
            podcastImageURL: podcastImageURL
        )
        await repository.save(favorite)
    }

    func remove(playbackKey: String) async {
        await repository.remove(playbackKey: playbackKey)
    }

    @discardableResult
    func toggleFavorite(
        episode: Episode,
        podcastTitle: String,
        podcastImageURL: URL?
    ) async -> Bool {
        if await isFavorite(playbackKey: episode.playbackKey) {
            await remove(playbackKey: episode.playbackKey)
            return false
        }

        await add(
            episode: episode,
            podcastTitle: podcastTitle,
            podcastImageURL: podcastImageURL
        )
        return true
    }

    // MARK: - Private

    private func makeFavoriteEpisode(
        from episode: Episode,
        podcastTitle: String,
        podcastImageURL: URL?
    ) -> FavoriteEpisode {
        FavoriteEpisode(
            playbackKey: episode.playbackKey,
            title: episode.title,
            podcastTitle: podcastTitle,
            podcastImageURL: podcastImageURL,
            summary: episode.description,
            audioURL: episode.audioURL,
            duration: episode.duration,
            publishedAt: episode.publishedAt,
            addedAt: .now
        )
    }
}

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

    func add(episode: Episode, podcastTitle: String) async {
        let favorite = makeFavoriteEpisode(from: episode, podcastTitle: podcastTitle)
        await repository.save(favorite)
    }

    func remove(playbackKey: String) async {
        await repository.remove(playbackKey: playbackKey)
    }

    @discardableResult
    func toggleFavorite(episode: Episode, podcastTitle: String) async -> Bool {
        if await isFavorite(playbackKey: episode.playbackKey) {
            await remove(playbackKey: episode.playbackKey)
            return false
        }

        await add(episode: episode, podcastTitle: podcastTitle)
        return true
    }

    // MARK: - Private

    private func makeFavoriteEpisode(from episode: Episode, podcastTitle: String) -> FavoriteEpisode {
        FavoriteEpisode(
            playbackKey: episode.playbackKey,
            title: episode.title,
            podcastTitle: podcastTitle,
            summary: episode.description,
            audioURL: episode.audioURL,
            duration: episode.duration,
            publishedAt: episode.publishedAt,
            addedAt: .now
        )
    }
}

//
//  FavoritesViewModel.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 12/03/25.
//

import Foundation
import Observation

@Observable
@MainActor
final class FavoritesViewModel {
    private let manageFavoritesUseCase: ManageFavoriteEpisodesUseCase

    var favorites: [FavoriteEpisode] = []
    var errorMessage: String?

    init(manageFavoritesUseCase: ManageFavoriteEpisodesUseCase) {
        self.manageFavoritesUseCase = manageFavoritesUseCase

        Task { @MainActor in
            await refresh()
        }
    }

    func refresh() async {
        favorites = await manageFavoritesUseCase.list()
    }

    func toggleFavorite(for episode: Episode, podcastTitle: String) async -> Bool {
        let isFavorite = await manageFavoritesUseCase.toggleFavorite(
            episode: episode,
            podcastTitle: podcastTitle
        )
        await refresh()
        return isFavorite
    }

    func remove(playbackKey: String, refreshAfterRemove: Bool = true) async {
        await manageFavoritesUseCase.remove(playbackKey: playbackKey)

        if refreshAfterRemove {
            await refresh()
        }
    }

    func isFavorite(playbackKey: String) async -> Bool {
        await manageFavoritesUseCase.isFavorite(playbackKey: playbackKey)
    }
}

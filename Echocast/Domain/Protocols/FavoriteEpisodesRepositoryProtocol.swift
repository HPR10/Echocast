//
//  FavoriteEpisodesRepositoryProtocol.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 12/03/25.
//

import Foundation

@MainActor
protocol FavoriteEpisodesRepositoryProtocol {
    func list() async -> [FavoriteEpisode]
    func save(_ episode: FavoriteEpisode) async
    func remove(playbackKey: String) async
    func exists(playbackKey: String) async -> Bool
}

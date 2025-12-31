//
//  MockPlaybackProgressRepository.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 22/12/25.
//

import Foundation

@MainActor
final class MockPlaybackProgressRepository: PlaybackProgressRepositoryProtocol {
    private var storage: [String: PlaybackProgress] = [:]

    func save(_ progress: PlaybackProgress) async {
        storage[progress.key] = progress
    }

    func fetch(for key: String) async -> PlaybackProgress? {
        storage[key]
    }

    func clear(for key: String) async {
        storage.removeValue(forKey: key)
    }
}

//
//  ManagePlaybackProgressUseCase.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 22/12/25.
//

import Foundation

@MainActor
final class ManagePlaybackProgressUseCase {
    private let repository: PlaybackProgressRepositoryProtocol
    private let completionThreshold: Double

    init(
        repository: PlaybackProgressRepositoryProtocol,
        completionThreshold: Double = 0.95
    ) {
        self.repository = repository
        self.completionThreshold = completionThreshold
    }

    func load(for key: String) async -> PlaybackProgress? {
        await repository.fetch(for: key)
    }

    func save(for key: String, position: TimeInterval, duration: TimeInterval?) async {
        let clamped = max(position, 0)

        if let duration, duration > 0, clamped >= duration * completionThreshold {
            await repository.clear(for: key)
            return
        }

        let progress = PlaybackProgress(
            key: key,
            position: clamped,
            duration: duration,
            updatedAt: .now
        )
        await repository.save(progress)
    }

    func clear(for key: String) async {
        await repository.clear(for: key)
    }
}

//
//  TechnologySearchViewModel.swift
//  Echocast
//
//  Created by OpenAI Assistant on 27/02/25.
//

import Foundation
import Observation

@Observable
@MainActor
final class TechnologySearchViewModel {
    private let fetchUseCase: FetchTechnologyPodcastsUseCase

    var podcasts: [DiscoveredPodcast] = []
    var isLoading = false
    var errorMessage: String?

    init(fetchUseCase: FetchTechnologyPodcastsUseCase) {
        self.fetchUseCase = fetchUseCase
    }

    func loadIfNeeded() async {
        guard podcasts.isEmpty, !isLoading else { return }
        await loadPodcasts()
    }

    func loadPodcasts() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            podcasts = try await fetchUseCase.execute()
        } catch {
            errorMessage = "Não foi possível carregar os podcasts agora."
        }

        isLoading = false
    }
}

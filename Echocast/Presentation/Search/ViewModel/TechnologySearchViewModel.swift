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
    private let syncPodcastUseCase: SyncPodcastFeedUseCase
    private let pageIncrement = 20

    private var currentMax = 20
    private var canLoadMore = true

    var podcasts: [DiscoveredPodcast] = []
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?
    var isLoadingPodcast = false
    var selectedPodcast: Podcast?
    var selectionError: String?
    var hasMore: Bool { canLoadMore }

    init(
        fetchUseCase: FetchTechnologyPodcastsUseCase,
        syncPodcastUseCase: SyncPodcastFeedUseCase
    ) {
        self.fetchUseCase = fetchUseCase
        self.syncPodcastUseCase = syncPodcastUseCase
    }

    func loadIfNeeded() async {
        guard podcasts.isEmpty, !isLoading else { return }
        await loadPodcasts()
    }

    func loadPodcasts() async {
        guard !isLoading, !isLoadingMore else { return }
        isLoading = true
        isLoadingMore = false
        errorMessage = nil
        canLoadMore = true
        currentMax = pageIncrement

        do {
            let fetched = try await fetchUseCase.execute(limit: currentMax, offset: 0)
            let unique = Self.uniquePodcasts(from: fetched)
            podcasts = unique
            canLoadMore = !unique.isEmpty
        } catch {
            podcasts = []
            canLoadMore = false
            errorMessage = "Não foi possível carregar os podcasts agora."
        }

        isLoading = false
    }

    func loadMoreIfNeeded(currentPodcast: DiscoveredPodcast) async {
        guard podcasts.last?.id == currentPodcast.id else { return }
        await loadMore()
    }

    func loadMore() async {
        guard canLoadMore, !isLoading, !isLoadingMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        currentMax += pageIncrement

        do {
            let fetched = try await fetchUseCase.execute(limit: currentMax, offset: 0)
            let unique = Self.uniquePodcasts(from: fetched)
            guard unique.count > podcasts.count else {
                canLoadMore = false
                return
            }
            podcasts = unique
            canLoadMore = true
        } catch {
            // Keep canLoadMore true to allow retry on next scroll.
        }
    }

    private static func uniquePodcasts(from podcasts: [DiscoveredPodcast]) -> [DiscoveredPodcast] {
        var seen = Set<Int>()
        return podcasts.filter { seen.insert($0.id).inserted }
    }

    func selectPodcast(_ discoveredPodcast: DiscoveredPodcast) async {
        guard !isLoadingPodcast else { return }
        isLoadingPodcast = true
        selectionError = nil

        do {
            let podcast = try await syncPodcastUseCase.execute(from: discoveredPodcast.feedURL)
            selectedPodcast = podcast
        } catch {
            selectionError = "Não foi possível abrir este podcast agora."
        }

        isLoadingPodcast = false
    }

    func clearSelectedPodcast() {
        selectedPodcast = nil
    }
}

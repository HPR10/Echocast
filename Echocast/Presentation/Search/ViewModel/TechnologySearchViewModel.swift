//
//  TechnologySearchViewModel.swift
//  Echocast
//
//  Created by OpenAI Assistant on 27/02/25.
//

import Foundation
import Observation
import Nuke

@Observable
@MainActor
final class TechnologySearchViewModel {
    private let fetchUseCase: FetchTechnologyPodcastsUseCase
    private let syncPodcastUseCase: SyncPodcastFeedUseCase
    private let resolveArtworkUseCase: ResolvePodcastArtworkUseCase
    private let pageIncrement = 20
    private let prefetchBatchSize = 12
    private let imagePrefetcher = ImagePrefetcher()

    private var currentMax = 20
    private var canLoadMore = true
    private var artworkAttempts = Set<URL>()
    private var artworkInFlight = Set<URL>()
    private var failedArtworkURLs = Set<URL>()

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
        syncPodcastUseCase: SyncPodcastFeedUseCase,
        resolveArtworkUseCase: ResolvePodcastArtworkUseCase
    ) {
        self.fetchUseCase = fetchUseCase
        self.syncPodcastUseCase = syncPodcastUseCase
        self.resolveArtworkUseCase = resolveArtworkUseCase
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
        artworkAttempts.removeAll()
        artworkInFlight.removeAll()
        failedArtworkURLs.removeAll()

        do {
            let fetched = try await fetchUseCase.execute(limit: currentMax, offset: 0)
            let unique = Self.uniquePodcasts(from: fetched)
            podcasts = unique
            canLoadMore = !unique.isEmpty
            scheduleArtworkResolution(for: unique)
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

    func prefetchImages(after podcast: DiscoveredPodcast) {
        guard let index = podcasts.firstIndex(where: { $0.id == podcast.id }) else { return }
        let startIndex = podcasts.index(after: index)
        let endIndex = podcasts.index(
            startIndex,
            offsetBy: prefetchBatchSize,
            limitedBy: podcasts.endIndex
        ) ?? podcasts.endIndex
        guard startIndex < endIndex else { return }
        let urls = podcasts[startIndex..<endIndex].compactMap(\.imageURL)
        guard !urls.isEmpty else { return }
        imagePrefetcher.startPrefetching(with: urls)
    }

    func loadMore() async {
        guard canLoadMore, !isLoading, !isLoadingMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        let existingIDs = Set(podcasts.map(\.id))
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
            let newItems = unique.filter { !existingIDs.contains($0.id) }
            scheduleArtworkResolution(for: newItems)
        } catch {
            // Keep canLoadMore true to allow retry on next scroll.
        }
    }

    private static func uniquePodcasts(from podcasts: [DiscoveredPodcast]) -> [DiscoveredPodcast] {
        var seen = Set<Int>()
        return podcasts.filter { seen.insert($0.id).inserted }
    }

    func resolveArtworkIfNeeded(for podcast: DiscoveredPodcast) async {
        guard podcast.imageURL == nil else { return }
        let feedURL = podcast.feedURL
        guard !artworkInFlight.contains(feedURL),
              !artworkAttempts.contains(feedURL) else { return }

        artworkInFlight.insert(feedURL)
        defer { artworkInFlight.remove(feedURL) }

        let resolvedImageURL = await resolveArtworkUseCase.execute(feedURL: feedURL)
        artworkAttempts.insert(feedURL)

        guard let resolvedImageURL else { return }
        failedArtworkURLs.remove(resolvedImageURL)
        podcasts = podcasts.map { item in
            guard item.feedURL == feedURL else { return item }
            return DiscoveredPodcast(
                id: item.id,
                title: item.title,
                author: item.author,
                imageURL: resolvedImageURL,
                feedURL: item.feedURL
            )
        }
    }

    func shouldAttemptArtworkLoad(for url: URL?) -> Bool {
        guard let url else { return false }
        return !failedArtworkURLs.contains(url)
    }

    func markArtworkLoadFailed(for url: URL?) {
        guard let url else { return }
        failedArtworkURLs.insert(url)
    }

    private func scheduleArtworkResolution(for podcasts: [DiscoveredPodcast]) {
        let candidates = podcasts.filter { $0.imageURL == nil }
        guard !candidates.isEmpty else { return }
        Task { [weak self] in
            guard let self else { return }
            for podcast in candidates {
                await self.resolveArtworkIfNeeded(for: podcast)
            }
        }
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

//
//  StudyFlowViewModel.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import Foundation
import Observation
import os

@Observable
@MainActor
final class StudyFlowViewModel {
    private let getCatalogUseCase: GetCuratedCatalogUseCase
    private let searchUseCase: SearchPodcastsUseCase
    private var loadTask: Task<Void, Never>?
    private var activeLoadID: UUID?
    private let logger = Logger(subsystem: "Echocast", category: "StudyFlow")

    var catalog: CuratedCatalog?
    var searchQuery = ""
    var inputErrorMessage: String?
    var state: StudyFlowState = .idle

    init(
        getCatalogUseCase: GetCuratedCatalogUseCase,
        searchUseCase: SearchPodcastsUseCase
    ) {
        self.getCatalogUseCase = getCatalogUseCase
        self.searchUseCase = searchUseCase
    }

    @discardableResult
    func startStudy(limit: Int = 25) async -> Bool {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            inputErrorMessage = "Digite um tema para buscar."
            return false
        }

        inputErrorMessage = nil
        let requestID = UUID()
        activeLoadID = requestID
        loadTask?.cancel()

        let task = Task { [weak self] in
            guard let self else { return }
            await self.performSearch(requestID: requestID, query: trimmedQuery, limit: limit)
        }
        loadTask = task
        await task.value
        return true
    }

    func clearResults() {
        state = .idle
        inputErrorMessage = nil
    }

    private func isActive(_ requestID: UUID) -> Bool {
        activeLoadID == requestID && !Task.isCancelled
    }

    private func performSearch(requestID: UUID, query: String, limit: Int) async {
        state = .loading

        defer {
            if activeLoadID == requestID, case .loading = state {
                state = .idle
            }
        }

        do {
            let remote = try await searchUseCase.execute(query: query, limit: limit)
            guard isActive(requestID) else { return }
            let mapped = remote.map(Self.mapDiscoveredPodcast)
            if !mapped.isEmpty {
                state = .loaded(results: mapped, query: query, source: .remote)
                return
            }
        } catch is CancellationError {
            return
        } catch {
            if !isActive(requestID) { return }
            logger.error("Falha na busca remota: \(String(describing: error))")
        }

        do {
            let catalog = try await getCatalogUseCase.execute()
            guard isActive(requestID) else { return }
            self.catalog = catalog
            let fallback = filterLocalCatalog(catalog, query: query)
            if fallback.isEmpty {
                state = .empty(query: query, source: .curated)
            } else {
                state = .loaded(results: fallback, query: query, source: .curated)
            }
        } catch is CancellationError {
            return
        } catch {
            if isActive(requestID) {
                logger.error("Falha ao carregar curadoria: \(String(describing: error))")
                state = .error("Não foi possível carregar a curadoria agora.")
            }
        }
    }

    private static func mapDiscoveredPodcast(_ podcast: DiscoveredPodcast) -> CuratedPodcast {
        CuratedPodcast(
            id: String(podcast.id),
            title: podcast.title,
            author: podcast.author,
            imageURL: podcast.imageURL,
            feedURL: podcast.feedURL,
            themes: [],
            levels: [],
            types: []
        )
    }

    private func filterLocalCatalog(_ catalog: CuratedCatalog, query: String) -> [CuratedPodcast] {
        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else { return catalog.podcasts }

        return catalog.podcasts.filter { podcast in
            let searchable = [
                podcast.title,
                podcast.author ?? "",
                podcast.themes.map(\.displayName).joined(separator: " "),
                podcast.levels.map(\.displayName).joined(separator: " "),
                podcast.types.map(\.displayName).joined(separator: " ")
            ].joined(separator: " ")
            return normalize(searchable).contains(normalizedQuery)
        }
    }

    private func normalize(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum StudySearchSource: String, Sendable, Equatable {
    case remote
    case curated
}

enum StudyFlowState: Equatable {
    case idle
    case loading
    case loaded(results: [CuratedPodcast], query: String, source: StudySearchSource)
    case empty(query: String, source: StudySearchSource)
    case error(String)
}

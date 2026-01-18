//
//  StudyFlowViewModel.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class StudyFlowViewModel {
    private let getCatalogUseCase: GetCuratedCatalogUseCase
    private let searchUseCase: SearchPodcastsUseCase
    private var loadTask: Task<Void, Never>?
    private var activeLoadID: UUID?

    var catalog: CuratedCatalog?
    var searchQuery = ""
    var submittedQuery: String?
    var searchResults: [CuratedPodcast] = []
    var isLoading = false
    var errorMessage: String?
    var searchSource: StudySearchSource?

    init(
        getCatalogUseCase: GetCuratedCatalogUseCase,
        searchUseCase: SearchPodcastsUseCase
    ) {
        self.getCatalogUseCase = getCatalogUseCase
        self.searchUseCase = searchUseCase
    }

    func startStudy(limit: Int = 25) async {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            errorMessage = "Digite um tema para buscar."
            return
        }

        let requestID = UUID()
        activeLoadID = requestID
        loadTask?.cancel()

        loadTask = Task { [weak self] in
            await self?.performSearch(requestID: requestID, query: trimmedQuery, limit: limit)
        }
    }

    func clearResults() {
        searchResults = []
        submittedQuery = nil
        searchSource = nil
        errorMessage = nil
    }

    private func isActive(_ requestID: UUID) -> Bool {
        activeLoadID == requestID && !Task.isCancelled
    }

    private func performSearch(requestID: UUID, query: String, limit: Int) async {
        isLoading = true
        errorMessage = nil
        searchSource = nil
        submittedQuery = query

        defer {
            if activeLoadID == requestID {
                isLoading = false
            }
        }

        do {
            let remote = try await searchUseCase.execute(query: query, limit: limit)
            guard isActive(requestID) else { return }
            let mapped = remote.map(Self.mapDiscoveredPodcast)
            if !mapped.isEmpty {
                searchResults = mapped
                searchSource = .remote
                return
            }
        } catch is CancellationError {
            return
        } catch {
            if !isActive(requestID) { return }
        }

        do {
            let catalog = try await getCatalogUseCase.execute()
            guard isActive(requestID) else { return }
            self.catalog = catalog
            let fallback = filterLocalCatalog(catalog, query: query)
            searchResults = fallback
            searchSource = .curated
            if fallback.isEmpty {
                errorMessage = "Nenhum podcast encontrado para esse tema."
            }
        } catch is CancellationError {
            return
        } catch {
            if isActive(requestID) {
                errorMessage = "Não foi possível carregar a curadoria agora."
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

enum StudySearchSource: String, Sendable {
    case remote
    case curated
}

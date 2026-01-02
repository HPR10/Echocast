//
//  AddPodcastViewModel.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 10/12/25.
//

import Foundation
import Observation

@Observable
@MainActor
final class AddPodcastViewModel {
    private let manageHistoryUseCase: ManageFeedHistoryUseCase
    private let syncPodcastUseCase: SyncPodcastFeedUseCase
    private let clearFeedCacheUseCase: ClearFeedCacheUseCase
    private let clearImageCacheUseCase: ClearImageCacheUseCase
    private var loadTask: Task<Void, Never>?
    private var activeLoadID: UUID?

    var inputText = ""
    var isLoading = false
    var loadedPodcast: Podcast?
    var errorMessage: String?

    init(
        manageHistoryUseCase: ManageFeedHistoryUseCase,
        syncPodcastUseCase: SyncPodcastFeedUseCase,
        clearFeedCacheUseCase: ClearFeedCacheUseCase,
        clearImageCacheUseCase: ClearImageCacheUseCase
    ) {
        self.manageHistoryUseCase = manageHistoryUseCase
        self.syncPodcastUseCase = syncPodcastUseCase
        self.clearFeedCacheUseCase = clearFeedCacheUseCase
        self.clearImageCacheUseCase = clearImageCacheUseCase
    }

    func loadFeed() {
        let requestID = UUID()
        activeLoadID = requestID
        loadTask?.cancel()

        loadTask = Task { @MainActor in
            await performLoad(requestID: requestID)
        }
    }

    func clearLoadedPodcast() {
        loadedPodcast = nil
    }

    func cancelLoad() {
        loadTask?.cancel()
        loadTask = nil
        activeLoadID = nil
        isLoading = false
    }

    func clearCache() async {
        await clearFeedCacheUseCase.execute()
        await clearImageCacheUseCase.execute()
    }

    func removeFromHistory(url: String) async {
        await manageHistoryUseCase.removeURL(url)
    }

    // MARK: - Validation

    func isValidURL(_ url: String) -> Bool {
        normalizedFeedURL(from: url) != nil
    }

    func shouldShowError(for url: String? = nil) -> Bool {
        let value = url ?? inputText
        return !value.isEmpty &&
        value.count > 8 &&
        !isValidURL(value)
    }

    func validationError(for url: String? = nil) -> String? {
        let value = url ?? inputText
        guard !value.isEmpty else { return nil }

        if !isValidURL(value) {
            return "URL inválida. Use http(s):// ou feed:// e inclua o caminho do feed."
        }

        return nil
    }

    private func performLoad(requestID: UUID) async {
        guard let url = normalizedFeedURL(from: inputText) else {
            if activeLoadID == requestID {
                errorMessage = FeedError.invalidURL.errorDescription
            }
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            if activeLoadID == requestID {
                isLoading = false
                loadTask = nil
            }
        }

        do {
            let podcast = try await syncPodcastUseCase.execute(from: url)
            guard isActive(requestID) else { return }
            await manageHistoryUseCase.addURL(url.absoluteString)
            guard isActive(requestID) else { return }
            loadedPodcast = podcast
        } catch is CancellationError {
            return
        } catch let error as FeedError {
            if isActive(requestID) {
                errorMessage = error.errorDescription
            }
        } catch {
            if isActive(requestID) {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func isActive(_ requestID: UUID) -> Bool {
        activeLoadID == requestID && !Task.isCancelled
    }

    private func normalizedFeedURL(from input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard var components = URLComponents(string: candidate) else { return nil }

        if let scheme = components.scheme?.lowercased() {
            switch scheme {
            case "http", "https":
                break
            case "feed":
                components.scheme = "https"
            case "feed+http":
                components.scheme = "http"
            case "feed+https":
                components.scheme = "https"
            default:
                return nil
            }
        } else {
            components.scheme = "https"
        }

        guard let url = components.url,
              let host = components.host,
              !host.isEmpty else {
            return nil
        }

        let hasPath = !(url.path.isEmpty || url.path == "/")
        let hasQuery = !(url.query?.isEmpty ?? true)
        guard hasPath || hasQuery else { return nil }

        return url
    }
}

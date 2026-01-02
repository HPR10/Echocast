//
//  AddPodcastView.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 10/12/25.
//

import SwiftUI
import SwiftData
import Observation

struct AddPodcastView: View {
    @State private var viewModel: AddPodcastViewModel
    @State private var navigationPath = NavigationPath()
    @State private var showClearCacheConfirmation = false
    @Query(sort: \FeedHistoryItem.addedAt, order: .reverse) private var feedHistory: [FeedHistoryItem]
    @Query private var podcasts: [PodcastEntity]

    init(viewModel: AddPodcastViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack(path: $navigationPath) {
            ZStack {
                VStack(spacing: 16) {
                    headerView
                    inputSection
                    historyList
                    Spacer()
                }
                .opacity(viewModel.isLoading ? 0 : 1)
                .allowsHitTesting(!viewModel.isLoading)

                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .padding()
            .navigationDestination(for: Podcast.self) { podcast in
                PodcastDetailView(
                    viewModel: PodcastDetailViewModel(podcast: podcast)
                )
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Limpar cache") {
                        showClearCacheConfirmation = true
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
        }
        .onChange(of: viewModel.loadedPodcast) { _, newPodcast in
            if let podcast = newPodcast {
                navigationPath.append(podcast)
                viewModel.clearLoadedPodcast()
            }
        }
        .onDisappear {
            viewModel.cancelLoad()
        }
        .alert("Erro", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .confirmationDialog(
            "Limpar cache de RSS e imagens?",
            isPresented: $showClearCacheConfirmation,
            titleVisibility: .visible
        ) {
            Button("Limpar", role: .destructive) {
                Task {
                    await viewModel.clearCache()
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Remove os caches e força uma nova busca do feed.")
        }
    }
}

// MARK: - View Components

private extension AddPodcastView {

    func inputBorderColor(hasError: Bool) -> Color {
        hasError ? .red : Color.secondary.opacity(0.35)
    }

    @ViewBuilder
    var headerView: some View {
        Text("URL do Podcast")
            .font(.title2)
            .fontWeight(.bold)
    }

    @ViewBuilder
    var inputSection: some View {
        @Bindable var viewModel = viewModel

        TextField("URL do RSS", text: $viewModel.inputText)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .textContentType(.URL)
            .disabled(viewModel.isLoading)
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(inputBorderColor(hasError: viewModel.shouldShowError()), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)

        if viewModel.shouldShowError(), let error = viewModel.validationError() {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
        }

        Button {
            viewModel.loadFeed()
        } label: {
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                HStack(spacing: 8) {
                    Text("Carregar")
                        .font(.headline.weight(.semibold))
                    Image(systemName: "arrow.right.circle.fill")
                        .imageScale(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .controlSize(.regular)
        .disabled(!viewModel.isValidURL(viewModel.inputText) || viewModel.isLoading)
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    var historyList: some View {
        @Bindable var viewModel = viewModel

        if feedHistory.isEmpty {
            ContentUnavailableView(
                "Nenhum histórico",
                systemImage: "tray.fill",
            )
        } else {
            List {
                Section("Recentes") {
                    let artworkByURL: [String: URL] = podcasts.reduce(into: [:]) { partialResult, podcast in
                        guard let artworkString = podcast.imageURL,
                              let artworkURL = URL(string: artworkString) else { return }
                        partialResult[podcast.feedURL] = artworkURL
                    }

                    ForEach(feedHistory) { item in
                        Button {
                            viewModel.inputText = item.url
                        } label: {
                            HStack(spacing: 12) {
                                historyArtwork(
                                    for: item.url,
                                    artworkByURL: artworkByURL
                                )
                                Text(item.url)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listRowSeparator(.visible)
        }
    }

    @ViewBuilder
    private func historyArtwork(
        for url: String,
        artworkByURL: [String: URL]
    ) -> some View {
        if let imageURL = artworkByURL[url] {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty, .failure:
                    placeholderIcon
                @unknown default:
                    placeholderIcon
                }
            }
            .frame(width: 28, height: 28)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
        } else {
            placeholderIcon
                .frame(width: 28, height: 28)
                .background(Color.gray.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private var placeholderIcon: some View {
        Image(systemName: "dot.radiowaves.left.and.right")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    var loadingOverlay: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text("Carregando...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .transition(.opacity)
        }
    }
}

// MARK: - Previews

#Preview("Estado Vazio") {
    AddPodcastView(
        viewModel: AddPodcastViewModel(
            manageHistoryUseCase: ManageFeedHistoryUseCase(
                repository: MockFeedHistoryRepository()
            ),
            syncPodcastUseCase: SyncPodcastFeedUseCase(
                loadPodcastUseCase: LoadPodcastFromRSSUseCase(
                    feedService: MockFeedService()
                ),
                repository: MockPodcastRepository()
            ),
            clearFeedCacheUseCase: ClearFeedCacheUseCase(
                feedService: MockFeedService()
            ),
            clearImageCacheUseCase: ClearImageCacheUseCase(
                imageCacheService: MockImageCacheService()
            )
        )
    )
    .modelContainer(for: FeedHistoryItem.self, inMemory: true)
    .environment(
        PlayerCoordinator(
            manageProgressUseCase: ManagePlaybackProgressUseCase(
                repository: MockPlaybackProgressRepository()
            ),
            playerService: MockAudioPlayerService(),
            resolvePlaybackSourceUseCase: nil
        )
    )
}

#Preview("Com Histórico") {
    let container = try! ModelContainer(
        for: FeedHistoryItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let sampleURLs = [
        "https://feeds.simplecast.com/54nAGcIl",
        "https://anchor.fm/s/example/podcast/rss",
        "https://rss.art19.com/the-daily"
    ]

    for url in sampleURLs {
        container.mainContext.insert(FeedHistoryItem(url: url))
    }

    return AddPodcastView(
        viewModel: AddPodcastViewModel(
            manageHistoryUseCase: ManageFeedHistoryUseCase(
                repository: MockFeedHistoryRepository()
            ),
            syncPodcastUseCase: SyncPodcastFeedUseCase(
                loadPodcastUseCase: LoadPodcastFromRSSUseCase(
                    feedService: MockFeedService()
                ),
                repository: MockPodcastRepository()
            ),
            clearFeedCacheUseCase: ClearFeedCacheUseCase(
                feedService: MockFeedService()
            ),
            clearImageCacheUseCase: ClearImageCacheUseCase(
                imageCacheService: MockImageCacheService()
            )
        )
    )
    .modelContainer(container)
    .environment(
        PlayerCoordinator(
            manageProgressUseCase: ManagePlaybackProgressUseCase(
                repository: MockPlaybackProgressRepository()
            ),
            playerService: MockAudioPlayerService(),
            resolvePlaybackSourceUseCase: nil
        )
    )
}

#Preview("URL Inválida") {
    struct InvalidURLPreview: View {
        @State private var viewModel: AddPodcastViewModel = {
            let viewModel = AddPodcastViewModel(
                manageHistoryUseCase: ManageFeedHistoryUseCase(
                    repository: MockFeedHistoryRepository()
                ),
                syncPodcastUseCase: SyncPodcastFeedUseCase(
                    loadPodcastUseCase: LoadPodcastFromRSSUseCase(
                        feedService: MockFeedService()
                    ),
                    repository: MockPodcastRepository()
                ),
                clearFeedCacheUseCase: ClearFeedCacheUseCase(
                    feedService: MockFeedService()
                ),
                clearImageCacheUseCase: ClearImageCacheUseCase(
                    imageCacheService: MockImageCacheService()
                )
            )
            viewModel.inputText = "http://podcast"
            return viewModel
        }()

        var body: some View {
            @Bindable var viewModel = viewModel

            VStack(spacing: 16) {
                Text("URL do Podcast")
                    .font(.title2)
                    .fontWeight(.bold)

                TextField("URL do RSS", text: $viewModel.inputText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .textContentType(.URL)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(inputBorderColor(hasError: viewModel.shouldShowError()), lineWidth: 1)
                    )

                if viewModel.shouldShowError(), let error = viewModel.validationError() {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button("Carregar") {}
                    .disabled(!viewModel.isValidURL(viewModel.inputText))
                    .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
        }
    }

    return InvalidURLPreview()
}

#Preview("URL Válida") {
    struct ValidURLPreview: View {
        @State private var viewModel: AddPodcastViewModel = {
            let viewModel = AddPodcastViewModel(
                manageHistoryUseCase: ManageFeedHistoryUseCase(
                    repository: MockFeedHistoryRepository()
                ),
                syncPodcastUseCase: SyncPodcastFeedUseCase(
                    loadPodcastUseCase: LoadPodcastFromRSSUseCase(
                        feedService: MockFeedService()
                    ),
                    repository: MockPodcastRepository()
                ),
                clearFeedCacheUseCase: ClearFeedCacheUseCase(
                    feedService: MockFeedService()
                ),
                clearImageCacheUseCase: ClearImageCacheUseCase(
                    imageCacheService: MockImageCacheService()
                )
            )
            viewModel.inputText = "https://feeds.simplecast.com/54nAGcIl"
            return viewModel
        }()

        var body: some View {
            @Bindable var viewModel = viewModel

            VStack(spacing: 16) {
                Text("URL do Podcast")
                    .font(.title2)
                    .fontWeight(.bold)

                TextField("URL do RSS", text: $viewModel.inputText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .textContentType(.URL)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(inputBorderColor(hasError: viewModel.shouldShowError()), lineWidth: 1)
                    )

                Button("Carregar") {}
                    .disabled(!viewModel.isValidURL(viewModel.inputText))
                    .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
        }
    }

    return ValidURLPreview()
}

#Preview("Dark Mode") {
    AddPodcastView(
        viewModel: AddPodcastViewModel(
            manageHistoryUseCase: ManageFeedHistoryUseCase(
                repository: MockFeedHistoryRepository()
            ),
            syncPodcastUseCase: SyncPodcastFeedUseCase(
                loadPodcastUseCase: LoadPodcastFromRSSUseCase(
                    feedService: MockFeedService()
                ),
                repository: MockPodcastRepository()
            ),
            clearFeedCacheUseCase: ClearFeedCacheUseCase(
                feedService: MockFeedService()
            ),
            clearImageCacheUseCase: ClearImageCacheUseCase(
                imageCacheService: MockImageCacheService()
            )
        )
    )
    .modelContainer(for: FeedHistoryItem.self, inMemory: true)
    .preferredColorScheme(.dark)
    .environment(
        PlayerCoordinator(
            manageProgressUseCase: ManagePlaybackProgressUseCase(
                repository: MockPlaybackProgressRepository()
            ),
            playerService: MockAudioPlayerService(),
            resolvePlaybackSourceUseCase: nil
        )
    )
}

#Preview("Landscape", traits: .landscapeLeft) {
    AddPodcastView(
        viewModel: AddPodcastViewModel(
            manageHistoryUseCase: ManageFeedHistoryUseCase(
                repository: MockFeedHistoryRepository()
            ),
            syncPodcastUseCase: SyncPodcastFeedUseCase(
                loadPodcastUseCase: LoadPodcastFromRSSUseCase(
                    feedService: MockFeedService()
                ),
                repository: MockPodcastRepository()
            ),
            clearFeedCacheUseCase: ClearFeedCacheUseCase(
                feedService: MockFeedService()
            ),
            clearImageCacheUseCase: ClearImageCacheUseCase(
                imageCacheService: MockImageCacheService()
            )
        )
    )
    .modelContainer(for: FeedHistoryItem.self, inMemory: true)
    .environment(
        PlayerCoordinator(
            manageProgressUseCase: ManagePlaybackProgressUseCase(
                repository: MockPlaybackProgressRepository()
            ),
            playerService: MockAudioPlayerService(),
            resolvePlaybackSourceUseCase: nil
        )
    )
}

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
    @Query(sort: \FeedHistoryItem.addedAt, order: .reverse) private var feedHistory: [FeedHistoryItem]
    @Query private var podcasts: [PodcastEntity]

    init(viewModel: AddPodcastViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack(path: $navigationPath) {
            ZStack {
                AppBackgroundView()

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
                .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
            }
            .navigationDestination(for: Podcast.self) { podcast in
                PodcastDetailView(
                    viewModel: PodcastDetailViewModel(podcast: podcast)
                )
            }
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
    }
}

// MARK: - View Components

extension AddPodcastView {
    @ViewBuilder
    var headerView: some View {
        Text("URL do Podcast")
            .font(.title2)
            .fontWeight(.bold)
    }

    @ViewBuilder
    var inputSection: some View {
        @Bindable var viewModel = viewModel

        AppTextField(
            placeholder: "URL do RSS",
            text: $viewModel.inputText,
            keyboardType: .URL,
            textContentType: .URL,
            textInputAutocapitalization: .never,
            autocorrectionDisabled: true,
            hasError: viewModel.shouldShowError()
        )
        .disabled(viewModel.isLoading)

        if viewModel.shouldShowError(), let error = viewModel.validationError() {
            Text(error)
                .font(AppTypography.caption)
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
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.removeFromHistory(url: item.url)
                                }
                            } label: {
                                Label("Excluir", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .listRowSeparator(.visible)
            .listRowBackground(Color.clear)
            .scrollContentBackground(.hidden)
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
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)
            }
            .transition(.opacity)
        }
    }
}

// MARK: - Previews

#Preview("AddPodcast - Estado vazio") {
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
            )
        )
    )
    .modelContainer(for: FeedHistoryItem.self, inMemory: true)
    .environment(
        PlayerCoordinator(
            manageProgressUseCase: ManagePlaybackProgressUseCase(
                repository: MockPlaybackProgressRepository()
            ),
            playerService: MockAudioPlayerService()
        )
    )
}

#Preview("AddPodcast - Com histórico") {
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
            )
        )
    )
    .modelContainer(container)
    .environment(
        PlayerCoordinator(
            manageProgressUseCase: ManagePlaybackProgressUseCase(
                repository: MockPlaybackProgressRepository()
            ),
            playerService: MockAudioPlayerService()
        )
    )
}

#Preview("AddPodcast - URL inválida") {
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

                AppTextField(
                    placeholder: "URL do RSS",
                    text: $viewModel.inputText,
                    keyboardType: .URL,
                    textContentType: .URL,
                    textInputAutocapitalization: .never,
                    autocorrectionDisabled: true,
                    hasError: viewModel.shouldShowError()
                )

                if viewModel.shouldShowError(), let error = viewModel.validationError() {
                    Text(error)
                        .font(AppTypography.caption)
                        .foregroundStyle(.red)
                }

                Button {

                } label: {
                    HStack(spacing: 8) {
                        Text("Carregar")
                            .font(.headline.weight(.semibold))
                        Image(systemName: "arrow.right.circle.fill")
                            .imageScale(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .controlSize(.regular)
                .disabled(!viewModel.isValidURL(viewModel.inputText))
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding()
        }
    }

    return InvalidURLPreview()
}

#Preview("AddPodcast - URL válida") {
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

                AppTextField(
                    placeholder: "URL do RSS",
                    text: $viewModel.inputText,
                    keyboardType: .URL,
                    textContentType: .URL,
                    textInputAutocapitalization: .never,
                    autocorrectionDisabled: true
                )

                Button {

                } label: {
                    HStack(spacing: 8) {
                        Text("Carregar")
                            .font(.headline.weight(.semibold))
                        Image(systemName: "arrow.right.circle.fill")
                            .imageScale(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .controlSize(.regular)
                .disabled(!viewModel.isValidURL(viewModel.inputText))
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding()
        }
    }

    return ValidURLPreview()
}

#Preview("AddPodcast - Dark mode") {
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
            playerService: MockAudioPlayerService()
        )
    )
}

#Preview("AddPodcast - Landscape", traits: .landscapeLeft) {
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
            )
        )
    )
    .modelContainer(for: FeedHistoryItem.self, inMemory: true)
    .environment(
        PlayerCoordinator(
            manageProgressUseCase: ManagePlaybackProgressUseCase(
                repository: MockPlaybackProgressRepository()
            ),
            playerService: MockAudioPlayerService()
        )
    )
}

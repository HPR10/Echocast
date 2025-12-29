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

    init(viewModel: AddPodcastViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack(path: $navigationPath) {
            VStack(spacing: 16) {
                headerView
                inputSection
                historyList
                Spacer()
            }
            .padding()
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

private extension AddPodcastView {

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
            .textFieldStyle(.roundedBorder)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .textContentType(.URL)
            .disabled(viewModel.isLoading)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(viewModel.shouldShowError() ? Color.red : Color.clear, lineWidth: 1)
            )

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
                Text("Carregar")
            }
        }
        .frame(minWidth: 120)
        .disabled(!viewModel.isValidURL(viewModel.inputText) || viewModel.isLoading)
        .buttonStyle(.borderedProminent)
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
            List(feedHistory) { item in
                Button {
                    viewModel.inputText = item.url
                } label: {
                    Text(item.url)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
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
            loadPodcastUseCase: LoadPodcastFromRSSUseCase(
                feedService: MockFeedService()
            )
        )
    )
    .modelContainer(for: FeedHistoryItem.self, inMemory: true)
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
            loadPodcastUseCase: LoadPodcastFromRSSUseCase(
                feedService: MockFeedService()
            )
        )
    )
    .modelContainer(container)
}

#Preview("URL Inválida") {
    struct InvalidURLPreview: View {
        @State private var viewModel = AddPodcastViewModel(
            manageHistoryUseCase: ManageFeedHistoryUseCase(
                repository: MockFeedHistoryRepository()
            ),
            loadPodcastUseCase: LoadPodcastFromRSSUseCase(
                feedService: MockFeedService()
            )
        )

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
                            .stroke(viewModel.shouldShowError() ? Color.red : Color.clear, lineWidth: 1)
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
        @State private var viewModel = AddPodcastViewModel(
            manageHistoryUseCase: ManageFeedHistoryUseCase(
                repository: MockFeedHistoryRepository()
            ),
            loadPodcastUseCase: LoadPodcastFromRSSUseCase(
                feedService: MockFeedService()
            )
        )

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
                            .stroke(viewModel.shouldShowError() ? Color.red : Color.clear, lineWidth: 1)
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
            loadPodcastUseCase: LoadPodcastFromRSSUseCase(
                feedService: MockFeedService()
            )
        )
    )
    .modelContainer(for: FeedHistoryItem.self, inMemory: true)
    .preferredColorScheme(.dark)
}

#Preview("Landscape", traits: .landscapeLeft) {
    AddPodcastView(
        viewModel: AddPodcastViewModel(
            manageHistoryUseCase: ManageFeedHistoryUseCase(
                repository: MockFeedHistoryRepository()
            ),
            loadPodcastUseCase: LoadPodcastFromRSSUseCase(
                feedService: MockFeedService()
            )
        )
    )
    .modelContainer(for: FeedHistoryItem.self, inMemory: true)
}

//
//  AddPodcastView.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 10/12/25.
//

import SwiftUI
import SwiftData

struct AddPodcastView: View {
    @State private var viewModel: AddPodcastViewModel
    @State private var inputText = ""
    @Query(sort: \FeedHistoryItem.addedAt, order: .reverse) private var feedHistory: [FeedHistoryItem]

    init(viewModel: AddPodcastViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 16) {
            headerView
            inputSection
            historyList
            Spacer()
        }
        .padding()
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
        TextField("URL do RSS", text: $inputText)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.URL)
            .autocapitalization(.none)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(viewModel.shouldShowError(for: inputText) ? Color.red : Color.clear, lineWidth: 1)
            )

        if viewModel.shouldShowError(for: inputText), let error = viewModel.validationError(for: inputText) {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
        }

        Button("Carregar") {
            Task {
                await viewModel.addURL(inputText, currentHistory: feedHistory)
            }
        }
        .disabled(!viewModel.isValidURL(inputText))
        .buttonStyle(.borderedProminent)
    }

    @ViewBuilder
    var historyList: some View {
        if feedHistory.isEmpty {
            ContentUnavailableView(
                "Nenhum histórico",
                systemImage: "tray.fill",
            )
        } else {
            List(feedHistory) { item in
                Text(item.url)
                    .onTapGesture {
                        inputText = item.url
                    }
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
            )
        )
        @State private var inputText = "invalid-url"

        var body: some View {
            VStack(spacing: 16) {
                Text("URL do Podcast")
                    .font(.title2)
                    .fontWeight(.bold)

                TextField("URL do RSS", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(viewModel.shouldShowError(for: inputText) ? Color.red : Color.clear, lineWidth: 1)
                    )

                if viewModel.shouldShowError(for: inputText), let error = viewModel.validationError(for: inputText) {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button("Carregar") {}
                    .disabled(!viewModel.isValidURL(inputText))
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
            )
        )
        @State private var inputText = "https://feeds.simplecast.com/podcast"

        var body: some View {
            VStack(spacing: 16) {
                Text("URL do Podcast")
                    .font(.title2)
                    .fontWeight(.bold)

                TextField("URL do RSS", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(viewModel.shouldShowError(for: inputText) ? Color.red : Color.clear, lineWidth: 1)
                    )

                Button("Carregar") {}
                    .disabled(!viewModel.isValidURL(inputText))
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
            )
        )
    )
    .modelContainer(for: FeedHistoryItem.self, inMemory: true)
}

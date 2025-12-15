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

        Button("Carregar") {
            Task {
                await viewModel.addURL(inputText, currentHistory: feedHistory)
            }
        }
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

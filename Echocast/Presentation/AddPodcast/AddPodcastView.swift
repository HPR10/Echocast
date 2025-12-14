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

    var feedURLBinding: Binding<String> {
        Binding(
            get: { viewModel.feedURL ?? "" },
            set: { viewModel.feedURL = $0.isEmpty ? nil : $0 }
        )
    }

    @ViewBuilder
    var headerView: some View {
        Text("URL do Podcast")
            .font(.title2)
            .fontWeight(.bold)
    }

    @ViewBuilder
    var inputSection: some View {
        TextField("URL do RSS", text: feedURLBinding)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.URL)
            .autocapitalization(.none)

        Button("Carregar") {
            viewModel.addURL(currentHistory: feedHistory)
        }
        .buttonStyle(.borderedProminent)
    }

    @ViewBuilder
    var historyList: some View {
        if !feedHistory.isEmpty {
            List(feedHistory) { item in
                Text(item.url)
                    .onTapGesture {
                        viewModel.selectURL(item.url)
                    }
            }
            .listStyle(.plain)
        }
    }
}

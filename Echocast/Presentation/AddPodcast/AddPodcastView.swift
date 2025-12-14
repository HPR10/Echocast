//
//  AddPodcastView.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 10/12/25.
//

import SwiftUI
import SwiftData

struct AddPodcastView: View {
    @State private var viewModel = AddPodcastViewModel()
    @Query(sort: \URLHistoryItem.addedAt, order: .reverse) private var urlHistory: [URLHistoryItem]
    @Environment(\.modelContext) private var modelContext

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
        TextField("URL do RSS", text: $viewModel.rssURL)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.URL)
            .autocapitalization(.none)

        Button("Carregar") {
            addURL()
        }
        .buttonStyle(.borderedProminent)
    }

    @ViewBuilder
    var historyList: some View {
        if !urlHistory.isEmpty {
            List(urlHistory) { item in
                Text(item.url)
                    .onTapGesture {
                        viewModel.selectURL(item.url)
                    }
            }
            .listStyle(.plain)
        }
    }

    func addURL() {
        guard !viewModel.rssURL.isEmpty else { return }

        // Remove duplicata se existir
        if let existing = urlHistory.first(where: { $0.url == viewModel.rssURL }) {
            modelContext.delete(existing)
        }

        // Adiciona nova URL
        let newItem = URLHistoryItem(url: viewModel.rssURL)
        modelContext.insert(newItem)

        // Limita a 10 itens
        let excess = urlHistory.count - 9
        if excess > 0 {
            for item in urlHistory.suffix(excess) {
                modelContext.delete(item)
            }
        }
    }
}

#Preview {
    AddPodcastView()
        .modelContainer(for: URLHistoryItem.self, inMemory: true)
}

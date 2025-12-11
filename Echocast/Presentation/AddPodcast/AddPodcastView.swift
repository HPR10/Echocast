//
//  AddPodcastView.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 10/12/25.
//

import SwiftUI

struct AddPodcastView: View {
    @StateObject private var viewModel = AddPodcastViewModel()

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
            Task {
                await viewModel.loadFeed()
            }
        }
        .buttonStyle(.borderedProminent)
    }

    @ViewBuilder
    var historyList: some View {
        if !viewModel.urlHistory.isEmpty {
            List(viewModel.urlHistory, id: \.self) { url in
                Text(url)
                    .onTapGesture {
                        viewModel.selectURL(url)
                    }
            }
            .listStyle(.plain)
        }
    }
}

#Preview {
    AddPodcastView()
}

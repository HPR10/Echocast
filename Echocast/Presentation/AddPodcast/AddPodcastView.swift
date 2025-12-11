//
//  AddPodcastView.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 10/12/25.
//

import SwiftUI

struct AddPodcastView: View {
    @StateObject private var viewModel = AddPodcastViewModel(repository: URLHistoryRepositoryImpl())

    var body: some View {
        VStack(spacing: 16) {
            Text("URL do Podcast")
                .font(.title2)
                .fontWeight(.bold)

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

            if !viewModel.urlHistory.isEmpty {
                List(viewModel.urlHistory, id: \.self) { url in
                    Text(url)
                        .onTapGesture {
                            viewModel.selectURL(url)
                        }
                }
                .listStyle(.plain)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    AddPodcastView()
}

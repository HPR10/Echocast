//
//  RootTabView.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import SwiftUI

struct RootTabView: View {
    @State private var addPodcastViewModel: AddPodcastViewModel
    @State private var downloadsViewModel: DownloadsViewModel
    @State private var favoritesViewModel: FavoritesViewModel

    init(
        addPodcastViewModel: AddPodcastViewModel,
        downloadsViewModel: DownloadsViewModel,
        favoritesViewModel: FavoritesViewModel
    ) {
        _addPodcastViewModel = State(initialValue: addPodcastViewModel)
        _downloadsViewModel = State(initialValue: downloadsViewModel)
        _favoritesViewModel = State(initialValue: favoritesViewModel)
    }

    var body: some View {
        TabView {
            AddPodcastView(viewModel: addPodcastViewModel)
                .tabItem {
                    Label("Início", systemImage: "house.fill")
                }

            FavoritesView(viewModel: favoritesViewModel)
                .tabItem {
                    Label("Favoritos", systemImage: "star.fill")
                }

            DownloadsView(viewModel: downloadsViewModel)
                .tabItem {
                    Label("Baixados", systemImage: "tray.and.arrow.down.fill")
                }

            SearchPlaceholderView()
                .tabItem {
                    Label("Buscar", systemImage: "magnifyingglass")
                }
        }
    }
}

private struct SearchPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Buscar",
                systemImage: "magnifyingglass",
                description: Text("Procure novos podcasts em breve.")
            )
            .navigationTitle("Buscar")
        }
    }
}

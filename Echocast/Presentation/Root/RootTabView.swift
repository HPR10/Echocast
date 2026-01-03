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
    @State private var technologySearchViewModel: TechnologySearchViewModel

    init(
        addPodcastViewModel: AddPodcastViewModel,
        downloadsViewModel: DownloadsViewModel,
        favoritesViewModel: FavoritesViewModel,
        technologySearchViewModel: TechnologySearchViewModel
    ) {
        _addPodcastViewModel = State(initialValue: addPodcastViewModel)
        _downloadsViewModel = State(initialValue: downloadsViewModel)
        _favoritesViewModel = State(initialValue: favoritesViewModel)
        _technologySearchViewModel = State(initialValue: technologySearchViewModel)
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

            TechnologySearchView(viewModel: technologySearchViewModel)
                .tabItem {
                    Label("Buscar", systemImage: "magnifyingglass")
                }
        }
    }
}

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

            ProfilePlaceholderView()
                .tabItem {
                    Label("Perfil", systemImage: "person.crop.circle")
                }
        }
    }
}

private struct ProfilePlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Perfil",
                systemImage: "person.crop.circle",
                description: Text("Configure sua conta e preferências em breve.")
            )
            .navigationTitle("Perfil")
        }
    }
}

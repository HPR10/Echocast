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

    init(
        addPodcastViewModel: AddPodcastViewModel,
        downloadsViewModel: DownloadsViewModel
    ) {
        _addPodcastViewModel = State(initialValue: addPodcastViewModel)
        _downloadsViewModel = State(initialValue: downloadsViewModel)
    }

    var body: some View {
        TabView {
            AddPodcastView(viewModel: addPodcastViewModel)
                .tabItem {
                    Label("Início", systemImage: "house.fill")
                }

            FavoritesPlaceholderView()
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

private struct FavoritesPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Favoritos",
                systemImage: "star.fill",
                description: Text("Adicione episódios aos favoritos para vê-los aqui.")
            )
            .navigationTitle("Favoritos")
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

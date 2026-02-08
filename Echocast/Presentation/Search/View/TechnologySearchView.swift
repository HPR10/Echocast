//
//  TechnologySearchView.swift
//  Echocast
//
//  Created by OpenAI Assistant on 27/02/25.
//

import SwiftUI
import NukeUI

struct TechnologySearchView: View {
    @State private var viewModel: TechnologySearchViewModel
    @State private var navigationPath = NavigationPath()
    @State private var isShowingSelectionError = false
    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.space12), count: 2)

    init(viewModel: TechnologySearchViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack(path: $navigationPath) {
            ZStack {
                AppBackgroundView()

                Group {
                    if viewModel.isLoading {
                        ProgressView("Carregando...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .multilineTextAlignment(.center)
                    } else if let error = viewModel.errorMessage {
                        ContentUnavailableView(
                            "Erro ao carregar",
                            systemImage: "exclamationmark.triangle.fill",
                            description: Text(error)
                        )
                        .overlay(alignment: .bottom) {
                            Button("Tentar novamente") {
                                Task { await viewModel.loadPodcasts() }
                            }
                            .buttonStyle(.borderedProminent)
                            .padding()
                        }
                    } else if viewModel.podcasts.isEmpty {
                        ContentUnavailableView(
                            "Nada por aqui",
                            systemImage: "magnifyingglass",
                            description: Text("Toque em atualizar para buscar podcasts de tecnologia.")
                        )
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: Spacing.space12) {
                                ForEach(viewModel.podcasts) { podcast in
                                    Button {
                                        Task { await viewModel.selectPodcast(podcast) }
                                    } label: {
                                        artworkView(for: podcast, viewModel: viewModel)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: Size.searchCardHeight)
                                        .clipShape(RoundedRectangle(cornerRadius: Spacing.radius12, style: .continuous))
                                        .appCardStyle()
                                    }
                                    .buttonStyle(.plain)
                                    .onAppear {
                                        viewModel.prefetchImages(after: podcast)
                                        Task {
                                            await viewModel.loadMoreIfNeeded(currentPodcast: podcast)
                                        }
                                    }
                                }

                                if viewModel.isLoadingMore {
                                    HStack {
                                        Spacer()
                                        ProgressView("Carregando mais...")
                                            .padding(.vertical, Spacing.space8)
                                        Spacer()
                                    }
                                    .gridCellColumns(columns.count)
                                } else if viewModel.hasMore {
                                    Color.clear
                                        .frame(height: Size.searchLoadMoreSentinelHeight)
                                        .gridCellColumns(columns.count)
                                        .onAppear {
                                            Task { await viewModel.loadMore() }
                                        }
                                }
                            }
                            .padding(.horizontal, Spacing.space16)
                            .padding(.vertical, Spacing.space12)
                        }
                        .refreshable {
                            await viewModel.loadPodcasts()
                        }
                    }
                }
            }
            .navigationDestination(for: Podcast.self) { podcast in
                PodcastDetailView(
                    viewModel: PodcastDetailViewModel(podcast: podcast)
                )
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .onChange(of: viewModel.selectedPodcast) { _, podcast in
            if let podcast {
                navigationPath.append(podcast)
                viewModel.clearSelectedPodcast()
            }
        }
        .alert("Erro ao abrir", isPresented: $isShowingSelectionError) {
            Button("OK") { }
        } message: {
            Text(viewModel.selectionError ?? "Tente novamente mais tarde.")
        }
        .onChange(of: viewModel.selectionError) { _, error in
            isShowingSelectionError = error != nil
        }
        .overlay {
            if viewModel.isLoadingPodcast {
                ZStack {
                    Colors.backgroundPrimary
                        .ignoresSafeArea()

                    VStack(spacing: Spacing.space12) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Carregando podcast...")
                            .font(Typography.body)
                            .foregroundStyle(Colors.textSecondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func artworkView(
        for podcast: DiscoveredPodcast,
        viewModel: TechnologySearchViewModel
    ) -> some View {
        if viewModel.shouldAttemptArtworkLoad(for: podcast.imageURL) {
            LazyImage(url: podcast.imageURL) { state in
                Group {
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else if state.isLoading {
                        ZStack {
                            RoundedRectangle(cornerRadius: Spacing.radius12, style: .continuous)
                                .fill(Colors.surfaceMuted)
                            ProgressView()
                        }
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: Spacing.radius12, style: .continuous)
                                .fill(Colors.surfaceMuted)
                            Image(systemName: "waveform")
                                .font(Typography.iconArtworkFallback)
                                .foregroundStyle(Colors.textSecondary)
                        }
                    }
                }
                .onChange(of: state.error != nil) { _, hasError in
                    if hasError {
                        viewModel.markArtworkLoadFailed(for: podcast.imageURL)
                    }
                }
            }
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: Spacing.radius12, style: .continuous)
                    .fill(Colors.surfaceMuted)
                Image(systemName: "waveform")
                    .font(Typography.iconArtworkFallback)
                    .foregroundStyle(Colors.textSecondary)
            }
        }
    }
}

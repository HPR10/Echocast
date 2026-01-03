//
//  TechnologySearchView.swift
//  Echocast
//
//  Created by OpenAI Assistant on 27/02/25.
//

import SwiftUI

struct TechnologySearchView: View {
    @State private var viewModel: TechnologySearchViewModel
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    init(viewModel: TechnologySearchViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
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
                        LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.podcasts) { podcast in
                            AsyncImage(url: podcast.imageURL) { phase in
                                switch phase {
                                case let .success(image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .empty:
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(.quaternary.opacity(0.2))
                                        ProgressView()
                                    }
                                default:
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(.quaternary.opacity(0.2))
                                        Image(systemName: "waveform")
                                            .font(.title2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(.quaternary, lineWidth: 0.5)
                            )
                            .onAppear {
                                Task {
                                    await viewModel.loadMoreIfNeeded(currentPodcast: podcast)
                                }
                            }
                        }

                            if viewModel.isLoadingMore {
                                HStack {
                                    Spacer()
                                    ProgressView("Carregando mais...")
                                        .padding(.vertical, 8)
                                    Spacer()
                                }
                                .gridCellColumns(columns.count)
                            } else if viewModel.hasMore {
                                Color.clear
                                    .frame(height: 1)
                                    .gridCellColumns(columns.count)
                                    .onAppear {
                                        Task { await viewModel.loadMore() }
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .refreshable {
                        await viewModel.loadPodcasts()
                    }
                }
            }
            .navigationTitle("Buscar")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await viewModel.loadPodcasts() }
                    } label: {
                        Label("Atualizar", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }
}

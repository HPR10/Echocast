//
//  TechnologySearchView.swift
//  Echocast
//
//  Created by OpenAI Assistant on 27/02/25.
//

import SwiftUI

struct TechnologySearchView: View {
    @State private var viewModel: TechnologySearchViewModel

    init(viewModel: TechnologySearchViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
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
                    List(viewModel.podcasts) { podcast in
                        HStack(spacing: 12) {
                            AsyncImage(url: podcast.imageURL) { phase in
                                switch phase {
                                case let .success(image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .empty:
                                    ProgressView()
                                default:
                                    Image(systemName: "waveform")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(.quaternary, lineWidth: 0.5)
                            )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(podcast.title)
                                    .font(.headline)
                                    .lineLimit(2)

                                if let author = podcast.author {
                                    Text(author)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Text(podcast.feedURL.absoluteString)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.insetGrouped)
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

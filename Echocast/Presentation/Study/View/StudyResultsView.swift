//
//  StudyResultsView.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import SwiftUI

struct StudyResultsView: View {
    @State private var viewModel: StudyFlowViewModel
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    init(viewModel: StudyFlowViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            Group {
                switch viewModel.state {
                case .loading:
                    VStack(spacing: 12) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Preparando seu estudo...")
                            .font(AppTypography.body)
                            .foregroundStyle(.secondary)
                        Text("Buscando podcasts relevantes para você.")
                            .font(AppTypography.meta)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .error(let message):
                    ContentUnavailableView(
                        "Não foi possível carregar",
                        systemImage: "exclamationmark.triangle.fill",
                        description: Text(message)
                    )
                    .overlay(alignment: .bottom) {
                        Button("Tentar novamente") {
                            Task {
                                await viewModel.startStudy()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom, 12)
                    }
                case .empty:
                    ContentUnavailableView(
                        "Nenhum podcast encontrado",
                        systemImage: "waveform",
                        description: Text("Volte e ajuste o tema para buscar novamente.")
                    )
                case .loaded(let results, let query, let source):
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Resultados para \"\(query)\"")
                                .font(AppTypography.sectionTitle)
                            if source == .curated {
                                Text("Mostrando curadoria local enquanto a busca principal está indisponível.")
                                    .font(AppTypography.meta)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppStyle.horizontalPadding)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(results) { podcast in
                                VStack(alignment: .leading, spacing: 8) {
                                    PodcastArtworkView(
                                        imageURL: podcast.imageURL,
                                        size: 120,
                                        cornerRadius: 16
                                    )
                                    Text(podcast.title)
                                        .font(AppTypography.title)
                                        .foregroundStyle(.primary)
                                        .lineLimit(2)
                                    if let author = podcast.author, !author.isEmpty {
                                        Text(author)
                                            .font(AppTypography.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .appCardStyle()
                            }
                        }
                        .padding(.horizontal, AppStyle.horizontalPadding)
                        .padding(.bottom, 32)
                    }
                case .idle:
                    ContentUnavailableView(
                        "Busque por um tema",
                        systemImage: "magnifyingglass",
                        description: Text("Volte para a tela anterior e escolha o que estudar.")
                    )
                }
            }
        }
        .navigationTitle("Resultados")
        .navigationBarTitleDisplayMode(.inline)
    }
}

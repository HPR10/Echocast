//
//  StudyResultsView.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import SwiftUI

struct StudyResultsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: StudyFlowViewModel
    private let columns = [
        GridItem(.flexible(), spacing: Spacing.space16),
        GridItem(.flexible(), spacing: Spacing.space16)
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
                    AppLoadingView(
                        message: "Preparando seu estudo...",
                        subtitle: "Buscando podcasts relevantes para você."
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .error(let message):
                    ContentUnavailableView(
                        "Não foi possível carregar",
                        systemImage: SFSymbols.warningFilled,
                        description: Text(message)
                    )
                    .overlay(alignment: .bottom) {
                        AppButton(
                            title: "Tentar novamente",
                            action: { Task { await viewModel.startStudy() } },
                            expands: false,
                            variant: .prominent,
                            controlSize: .regular
                        )
                        .padding(.bottom, Spacing.space12)
                    }
                case .empty:
                    ContentUnavailableView(
                        "Nenhum podcast encontrado",
                        systemImage: SFSymbols.waveform,
                        description: Text("Volte e ajuste o tema para buscar novamente.")
                    )
                case .loaded(let results, let query, let source):
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.space12) {
                            Text("Resultados para \"\(query)\"")
                                .font(Typography.sectionTitle)
                            if source == .curated {
                                Text("Mostrando curadoria local enquanto a busca principal está indisponível.")
                                    .font(Typography.meta)
                                    .foregroundStyle(
                                        Colors.text(.secondary, on: .appBackground, scheme: colorScheme)
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.horizontalPadding)

                        LazyVGrid(columns: columns, spacing: Spacing.space16) {
                            ForEach(results) { podcast in
                                VStack(alignment: .leading, spacing: Spacing.space8) {
                                    PodcastArtworkView(
                                        imageURL: podcast.imageURL,
                                        size: Size.studyResultArtwork,
                                        cornerRadius: Spacing.radius16
                                    )
                                    Text(podcast.title)
                                        .font(Typography.title)
                                        .foregroundStyle(
                                            Colors.text(.primary, on: .card, scheme: colorScheme)
                                        )
                                        .lineLimit(2)
                                    if let author = podcast.author, !author.isEmpty {
                                        Text(author)
                                            .font(Typography.caption)
                                            .foregroundStyle(
                                                Colors.text(.secondary, on: .card, scheme: colorScheme)
                                            )
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .appCardStyle()
                            }
                        }
                        .padding(.horizontal, Spacing.horizontalPadding)
                        .padding(.bottom, Spacing.space32)
                    }
                case .idle:
                    ContentUnavailableView(
                        "Busque por um tema",
                        systemImage: SFSymbols.search,
                        description: Text("Volte para a tela anterior e escolha o que estudar.")
                    )
                }
            }
        }
        .navigationTitle("Resultados")
        .navigationBarTitleDisplayMode(.inline)
    }
}

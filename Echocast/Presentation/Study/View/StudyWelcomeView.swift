//
//  StudyWelcomeView.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import SwiftUI

struct StudyWelcomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: StudyFlowViewModel
    @FocusState private var isFocused: Bool
    private let onContinue: () -> Void
    private let onSkip: () -> Void
    private let isFirstRun: Bool

    init(
        viewModel: StudyFlowViewModel,
        isFirstRun: Bool,
        onSkip: @escaping () -> Void,
        onContinue: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.isFirstRun = isFirstRun
        self.onSkip = onSkip
        self.onContinue = onContinue
    }

    private var isLoading: Bool {
        if case .loading = viewModel.state {
            return true
        }
        return false
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.space20) {
                    VStack(alignment: .leading, spacing: Spacing.space8) {
                        Text("Explore conteúdos técnicos")
                            .font(Typography.heroTitle)
                            .foregroundStyle(
                                Colors.text(.primary, on: .appBackground, scheme: colorScheme)
                            )
                        Text("Podcasts técnicos curados para estudo, carreira e evolução profissional.")
                            .font(Typography.body)
                            .foregroundStyle(
                                Colors.text(.secondary, on: .appBackground, scheme: colorScheme)
                            )
                    }

                    AppTextField(
                        placeholder: "Buscar por tema, tecnologia ou podcast",
                        text: $viewModel.searchQuery,
                        leadingSystemImage: SFSymbols.search,
                        textInputAutocapitalization: .never,
                        autocorrectionDisabled: true,
                        submitLabel: .search,
                        focus: $isFocused
                    )

                    if let errorMessage = viewModel.inputErrorMessage {
                        Text(errorMessage)
                            .font(Typography.meta)
                            .foregroundStyle(Colors.feedbackError)
                    }

                    VStack(spacing: Spacing.space12) {
                        AppIconLabel(
                            text: "Frontend & UI",
                            symbol: SFSymbols.studyFrontend,
                            font: Typography.title
                        )
                        .appCardStyle()

                        AppIconLabel(
                            text: "Backend & APIs",
                            symbol: SFSymbols.studyBackend,
                            font: Typography.title
                        )
                        .appCardStyle()

                        AppIconLabel(
                            text: "Arquitetura & Sistemas",
                            symbol: SFSymbols.studyArchitecture,
                            font: Typography.title
                        )
                        .appCardStyle()

                        AppIconLabel(
                            text: "Carreira em Tecnologia",
                            symbol: SFSymbols.studyCareer,
                            font: Typography.title
                        )
                        .appCardStyle()
                    }

                    AppButton(
                        title: "Explorar episódios",
                        action: {
                            viewModel.clearResults()
                            Task {
                                if await viewModel.startStudy() {
                                    onContinue()
                                }
                            }
                        },
                        isLoading: isLoading,
                        isDisabled: isLoading,
                        expands: true,
                        variant: .glass,
                        controlSize: .large,
                        glassTint: Colors.brand300
                    )

                }
                .padding(.horizontal, Spacing.horizontalPadding)
                .padding(.top, Spacing.space24)
                .padding(.bottom, Spacing.space32)
            }
        }
        .navigationTitle("Estudo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isFirstRun {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Pular") {
                        onSkip()
                    }
                }
            }
        }
        .onDisappear {
            if isFirstRun {
                onSkip()
            }
        }
        .onAppear {
            if isFirstRun {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isFocused = true
                }
            }
        }
    }
}

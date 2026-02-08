//
//  StudyWelcomeView.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import SwiftUI

struct StudyWelcomeView: View {
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
                            .foregroundStyle(Colors.textPrimary)
                        Text("Podcasts técnicos curados para estudo, carreira e evolução profissional.")
                            .font(Typography.body)
                            .foregroundStyle(Colors.textSecondary)
                    }

                    AppTextField(
                        placeholder: "Buscar por tema, tecnologia ou podcast",
                        text: $viewModel.searchQuery,
                        leadingSystemImage: "magnifyingglass",
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
                        Label("Frontend & UI", systemImage: "laptopcomputer")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .appCardStyle()
                        Label("Backend & APIs", systemImage: "server.rack")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .appCardStyle()
                        Label("Arquitetura & Sistemas", systemImage: "flowchart")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .appCardStyle()
                        Label("Carreira em Tecnologia", systemImage: "briefcase")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .appCardStyle()
                    }
                    .font(Typography.title)
                    .foregroundStyle(Colors.textPrimary)
                    .labelStyle(.titleAndIcon)

                    Button {
                        viewModel.clearResults()
                        Task {
                            if await viewModel.startStudy() {
                                onContinue()
                            }
                        }
                    } label: {
                        HStack {
                            Text("Explorar episódios")
                            if isLoading {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)

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

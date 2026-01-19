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

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isFirstRun ? "Seu estudo em áudio começa aqui." : "Escolha seu próximo estudo.")
                            .font(AppTypography.heroTitle)
                            .foregroundStyle(.primary)
                        Text("Sem ruído, sem distrações. Apenas podcasts técnicos para você evoluir.")
                            .font(AppTypography.body)
                            .foregroundStyle(.secondary)
                    }

                    if isFirstRun {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Curadoria focada em tecnologia e carreira dev.", systemImage: "checkmark.seal")
                            Label("Recomece exatamente de onde parou.", systemImage: "bookmark")
                            Label("Crie hábito de estudo com áudio.", systemImage: "waveform")
                        }
                        .font(AppTypography.body)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("O que você quer estudar agora?")
                            .font(AppTypography.sectionTitle)
                        TextField("Ex: Swift, backend, arquitetura...", text: $viewModel.searchQuery)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .focused($isFocused)
                            .submitLabel(.search)
                            .padding(.top, 4)
                    }
                    .appCardStyle()

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(AppTypography.meta)
                            .foregroundStyle(.red)
                    }

                    Button {
                        let trimmed = viewModel.searchQuery
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else {
                            viewModel.errorMessage = "Digite um tema para buscar."
                            return
                        }
                        viewModel.clearResults()
                        Task {
                            await viewModel.startStudy()
                            onContinue()
                        }
                    } label: {
                        HStack {
                            Text("Preparar meu estudo")
                            if viewModel.isLoading {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)

                    if !isFirstRun {
                        Text("Dica: você pode buscar por temas, tecnologias ou áreas específicas.")
                            .font(AppTypography.meta)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, AppStyle.horizontalPadding)
                .padding(.top, 24)
                .padding(.bottom, 32)
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

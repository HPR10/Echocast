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
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Explore conteúdos técnicos")
                            .font(AppTypography.heroTitle)
                            .foregroundStyle(.primary)
                        Text("Podcasts técnicos curados para estudo, carreira e evolução profissional.")
                            .font(AppTypography.body)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Buscar por tema, tecnologia ou podcast", text: $viewModel.searchQuery)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .focused($isFocused)
                            .submitLabel(.search)
                    }
                    .appCardStyle()

                    if let errorMessage = viewModel.inputErrorMessage {
                        Text(errorMessage)
                            .font(AppTypography.meta)
                            .foregroundStyle(.red)
                    }

                    VStack(spacing: 12) {
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
                    .font(AppTypography.title)
                    .foregroundStyle(.primary)
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

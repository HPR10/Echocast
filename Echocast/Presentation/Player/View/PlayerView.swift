//
//  PlayerView.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 21/12/25.
//

import SwiftUI
import Observation

struct PlayerView: View {
    @State private var viewModel: PlayerViewModel

    init(viewModel: PlayerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 24) {
            headerSection
            playbackSection
            Spacer()
        }
        .padding()
        .navigationTitle("Player")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.stop()
        }
        .alert("Erro", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - View Components

private extension PlayerView {

    @ViewBuilder
    var headerSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.podcastTitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text(viewModel.episode.title)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            if let description = viewModel.episode.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder
    var playbackSection: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.togglePlayback()
            } label: {
                Label(viewModel.isPlaying ? "Pausar" : "Reproduzir", systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .frame(minWidth: 160)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.hasAudio)

            if !viewModel.hasAudio {
                Text("Audio indisponivel para este episodio.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Previews

#Preview("Com Audio") {
    NavigationStack {
        PlayerView(
            viewModel: PlayerViewModel(
                episode: Episode(
                    title: "Episodio 1: Introducao",
                    description: "Um episodio de teste para o player.",
                    audioURL: URL(string: "https://example.com/audio.mp3")
                ),
                podcastTitle: "Podcast de Teste"
            )
        )
    }
}

#Preview("Sem Audio") {
    NavigationStack {
        PlayerView(
            viewModel: PlayerViewModel(
                episode: Episode(
                    title: "Episodio sem audio",
                    description: "Episodio sem URL de audio."
                ),
                podcastTitle: "Podcast de Teste"
            )
        )
    }
}

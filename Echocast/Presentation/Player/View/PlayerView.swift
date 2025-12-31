//
//  PlayerView.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 21/12/25.
//

import SwiftUI
import Observation

struct PlayerRouteView: View {
    @Environment(PlayerCoordinator.self) private var playerCoordinator
    let episode: Episode
    let podcastTitle: String

    var body: some View {
        let viewModel = playerCoordinator.prepare(
            episode: episode,
            podcastTitle: podcastTitle
        )
        PlayerView(viewModel: viewModel)
    }
}

struct PlayerView: View {
    let viewModel: PlayerViewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 24) {
            headerSection
            progressSection
            controlSection
            playbackSection
            Spacer()
        }
        .padding()
        .navigationTitle("Player")
        .navigationBarTitleDisplayMode(.inline)
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

    @ViewBuilder
    var controlSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 24) {
                Button {
                    viewModel.skipBackward()
                } label: {
                    Label("-30s", systemImage: "gobackward.30")
                        .frame(minWidth: 80)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.hasAudio || !viewModel.isSeekable)

                Button {
                    viewModel.skipForward()
                } label: {
                    Label("+15s", systemImage: "goforward.15")
                        .frame(minWidth: 80)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.hasAudio || !viewModel.isSeekable)
            }

            HStack {
                Text("Velocidade")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Menu {
                    ForEach(viewModel.availablePlaybackRates, id: \.self) { rate in
                        Button(String(format: "%.2gx", rate)) {
                            viewModel.setPlaybackRate(rate)
                        }
                    }
                } label: {
                    Label(viewModel.playbackRateText, systemImage: "speedometer")
                        .frame(minWidth: 120)
                }
                .disabled(!viewModel.hasAudio)
            }
        }
    }

    @ViewBuilder
    var progressSection: some View {
        let maxDuration = max(viewModel.duration, 1)

        VStack(spacing: 8) {
            if viewModel.isBuffering {
                HStack(spacing: 8) {
                    ProgressView()
                    Text(viewModel.bufferingMessage ?? "Carregando...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }

            Slider(
                value: Binding(
                    get: { viewModel.currentTime },
                    set: { viewModel.currentTime = $0 }
                ),
                in: 0...maxDuration,
                onEditingChanged: { editing in
                    if editing {
                        viewModel.beginScrubbing()
                    } else {
                        viewModel.endScrubbing(at: viewModel.currentTime)
                    }
                }
            )
            .disabled(!viewModel.isSeekable || !viewModel.hasAudio)

            HStack {
                Text(viewModel.currentTimeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(viewModel.durationText)
                    .font(.caption)
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
                podcastTitle: "Podcast de Teste",
                manageProgressUseCase: ManagePlaybackProgressUseCase(
                    repository: MockPlaybackProgressRepository()
                )
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
                podcastTitle: "Podcast de Teste",
                manageProgressUseCase: ManagePlaybackProgressUseCase(
                    repository: MockPlaybackProgressRepository()
                )
            )
        )
    }
}

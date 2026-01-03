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
    @Environment(DownloadsViewModel.self) private var downloadsViewModel
    @Environment(FavoritesViewModel.self) private var favoritesViewModel
    let episode: Episode
    let podcastTitle: String
    let podcastImageURL: URL?

    var body: some View {
        let viewModel = playerCoordinator.prepare(
            episode: episode,
            podcastTitle: podcastTitle
        )
        PlayerView(
            viewModel: viewModel,
            downloadsViewModel: downloadsViewModel,
            favoritesViewModel: favoritesViewModel,
            podcastImageURL: podcastImageURL
        )
            .onDisappear {
                playerCoordinator.handleViewDisappear(for: episode)
            }
    }
}

struct PlayerView: View {
    let viewModel: PlayerViewModel
    let downloadsViewModel: DownloadsViewModel?
    let favoritesViewModel: FavoritesViewModel?
    let podcastImageURL: URL?
    @State private var downloadError: String?
    @State private var isFavorite = false

    init(
        viewModel: PlayerViewModel,
        downloadsViewModel: DownloadsViewModel? = nil,
        favoritesViewModel: FavoritesViewModel? = nil,
        podcastImageURL: URL? = nil
    ) {
        self.viewModel = viewModel
        self.downloadsViewModel = downloadsViewModel
        self.favoritesViewModel = favoritesViewModel
        self.podcastImageURL = podcastImageURL
        _downloadError = State(initialValue: nil)
        _isFavorite = State(initialValue: false)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        GeometryReader { geometry in
            let bannerSize = min(
                max(geometry.size.height * 0.25, 170),
                geometry.size.width * 0.75
            )

            VStack(spacing: 24) {
                PodcastArtworkView(
                    imageURL: podcastImageURL,
                    size: bannerSize
                )
                headerSection
                progressSection
                controlSection
                playbackSection
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .navigationTitle("Player")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Erro", isPresented: .init(
            get: { viewModel.errorMessage != nil || downloadError != nil },
            set: { if !$0 { viewModel.errorMessage = nil; downloadError = nil } }
        )) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? downloadError ?? "")
        }
        .task {
            await loadFavoriteState()
        }
    }
}

// MARK: - View Components

private extension PlayerView {
    @ViewBuilder
    var headerSection: some View {
        let playbackKey = viewModel.episode.playbackKey
        let activeDownload = downloadsViewModel?.activeDownloads
            .first { $0.playbackKey == playbackKey }
        let isDownloaded = downloadsViewModel?.downloads
            .contains { $0.playbackKey == playbackKey } ?? false

        VStack(spacing: 8) {
            HStack(spacing: 8) {
                downloadButton(
                    activeDownload: activeDownload,
                    isDownloaded: isDownloaded
                )
                if let activeDownload,
                   let percentLabel = downloadProgressPercentage(for: activeDownload) {
                    Text(percentLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }
                Spacer()
                favoriteButton
            }

            if let publishedAt = viewModel.episode.publishedAt {
                Text(publishedAt, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.episode.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)

                Text(viewModel.podcastTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let description = viewModel.episode.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    @ViewBuilder
    private func downloadButton(
        activeDownload: DownloadProgress?,
        isDownloaded: Bool
    ) -> some View {
        if downloadsViewModel == nil {
            Color.clear
                .frame(width: 34, height: 34)
                .opacity(0)
        } else if let activeDownload {
            ZStack {
                Circle()
                    .stroke(.gray.opacity(0.2), lineWidth: 2)
                    .frame(width: 34, height: 34)

                ProgressView(value: activeDownload.fractionCompleted ?? 0)
                    .progressViewStyle(.circular)
                    .frame(width: 34, height: 34)
            }
            .animation(.easeInOut, value: activeDownload.fractionCompleted)
            .accessibilityLabel("Baixando episodio")
        } else if isDownloaded {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.blue)
                .symbolEffect(.bounce, value: isDownloaded)
                .accessibilityLabel("Episodio baixado")
        } else {
            Button {
                Task { @MainActor in
                    guard let downloadsViewModel else { return }
                    downloadError = await downloadsViewModel.enqueueDownload(
                        for: viewModel.episode,
                        podcastTitle: viewModel.podcastTitle,
                        podcastImageURL: podcastImageURL
                    )
            }
        } label: {
            Image(systemName: "arrow.down.circle")
                .font(.title2.weight(.semibold))
        }
            .buttonStyle(.plain)
            .disabled(viewModel.episode.audioURL == nil)
            .accessibilityLabel("Baixar episodio")
        }
    }

    func downloadProgressPercentage(for progress: DownloadProgress) -> String? {
        guard let fraction = progress.fractionCompleted else { return nil }
        let percent = Int((fraction * 100).rounded())
        return "\(percent)%"
    }

    private var favoriteButton: some View {
        Button {
            Task { @MainActor in
                guard let favoritesViewModel else { return }
                let newState = await favoritesViewModel.toggleFavorite(
                    for: viewModel.episode,
                    podcastTitle: viewModel.podcastTitle,
                    podcastImageURL: podcastImageURL
                )
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isFavorite = newState
                }
            }
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.title2.weight(.semibold))
                .foregroundStyle(isFavorite ? Color.yellow : Color.secondary)
                .scaleEffect(isFavorite ? 1.1 : 1.0)
                .symbolEffect(.bounce, value: isFavorite)
                .accessibilityLabel(isFavorite ? "Remover dos favoritos" : "Adicionar aos favoritos")
        }
        .buttonStyle(.plain)
        .disabled(favoritesViewModel == nil)
    }

    @ViewBuilder
    var playbackSection: some View {
        if !viewModel.hasAudio {
            Text("Audio indisponivel para este episodio.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    var controlSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                Spacer(minLength: 16)

                Button {
                    viewModel.skipBackward()
                } label: {
                    Image(systemName: "gobackward.30")
                        .font(.system(size: 32, weight: .semibold))
                        .frame(width: 72, height: 48)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Voltar 30 segundos")
                .disabled(!viewModel.hasAudio || !viewModel.isSeekable)

                Button {
                    viewModel.togglePlayback()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 40, weight: .bold))
                        .frame(width: 80, height: 56)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(viewModel.isPlaying ? "Pausar" : "Reproduzir")
                .disabled(!viewModel.hasAudio)

                Button {
                    viewModel.skipForward()
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.system(size: 32, weight: .semibold))
                        .frame(width: 72, height: 48)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Avancar 15 segundos")
                .disabled(!viewModel.hasAudio || !viewModel.isSeekable)

                Spacer(minLength: 8)

                Menu {
                    ForEach(viewModel.availablePlaybackRates, id: \.self) { rate in
                        Button {
                            viewModel.setPlaybackRate(rate)
                        } label: {
                            HStack {
                                Text(String(format: "%.2gx", rate))
                                if rate == viewModel.playbackRate {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .accessibilityLabel("Opcoes de playback")
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

    func loadFavoriteState() async {
        guard let favoritesViewModel else { return }
        isFavorite = await favoritesViewModel.isFavorite(
            playbackKey: viewModel.episode.playbackKey
        )
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
                ),
                playerService: MockAudioPlayerService(),
                resolvePlaybackSourceUseCase: nil
            ),
            podcastImageURL: URL(string: "https://example.com/image.jpg")
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
                ),
                playerService: MockAudioPlayerService(),
                resolvePlaybackSourceUseCase: nil
            )
        )
    }
}

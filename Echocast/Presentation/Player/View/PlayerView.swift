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
            let bannerHeight = geometry.size.height * 0.25

            VStack(spacing: 24) {
                podcastBanner(height: bannerHeight)
                headerSection
                downloadSection
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
    func podcastBanner(height: CGFloat) -> some View {
        Group {
            if let podcastImageURL {
                AsyncImage(url: podcastImageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderBanner
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholderBanner
                    }
                }
            } else {
                placeholderBanner
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var placeholderBanner: some View {
        LinearGradient(colors: [.purple.opacity(0.6), .blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay {
                Image(systemName: "mic.fill")
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
    }

    @ViewBuilder
    var downloadSection: some View {
        if let downloadsViewModel {
            let playbackKey = viewModel.episode.playbackKey
            let activeDownload = downloadsViewModel.activeDownloads
                .first { $0.playbackKey == playbackKey }
            let isDownloaded = downloadsViewModel.downloads
                .contains { $0.playbackKey == playbackKey }

            VStack(spacing: 8) {
                if let activeDownload {
                    if let fraction = activeDownload.fractionCompleted {
                        ProgressView(value: fraction)
                    } else {
                        ProgressView()
                    }
                    Text(downloadProgressLabel(for: activeDownload))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if isDownloaded {
                    Label("Baixado", systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        Task { @MainActor in
                            downloadError = await downloadsViewModel.enqueueDownload(
                                for: viewModel.episode,
                                podcastTitle: viewModel.podcastTitle
                            )
                        }
                    } label: {
                        Label("Baixar episodio", systemImage: "arrow.down.circle")
                            .frame(minWidth: 160)
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.episode.audioURL == nil)
                }
            }
        }
    }

    func downloadProgressLabel(for progress: DownloadProgress) -> String {
        switch progress.state {
        case .queued:
            return "Na fila"
        case .running:
            if let fraction = progress.fractionCompleted {
                let percent = Int((fraction * 100).rounded())
                return "Baixando... \(percent)%"
            }
            return "Baixando..."
        case .finished:
            return "Concluido"
        case .failed(let message):
            return "Falhou: \(message)"
        case .cancelled:
            return "Cancelado"
        }
    }

    @ViewBuilder
    var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                favoriteButton
            }

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

    private var favoriteButton: some View {
        Button {
            Task { @MainActor in
                guard let favoritesViewModel else { return }
                let newState = await favoritesViewModel.toggleFavorite(
                    for: viewModel.episode,
                    podcastTitle: viewModel.podcastTitle
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

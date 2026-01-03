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
                Menu {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, 4)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .truncationMode(.tail)

                        Image(systemName: "ellipsis")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
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
                glowCircle(size: 40)

                Circle()
                    .stroke(Color.primary.opacity(0.25), lineWidth: 2)
                    .frame(width: 34, height: 34)

                ProgressView(value: activeDownload.fractionCompleted ?? 0)
                    .progressViewStyle(.circular)
                    .frame(width: 34, height: 34)
            }
            .animation(.easeInOut, value: activeDownload.fractionCompleted)
            .foregroundStyle(.primary)
            .accessibilityLabel("Baixando episodio")
        } else if isDownloaded {
            ZStack {
                glowCircle(size: 40)
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2.weight(.semibold))
            }
            .foregroundStyle(.primary)
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
            ZStack {
                glowCircle(size: 40)
                Image(systemName: "arrow.down.circle")
                    .font(.title2.weight(.semibold))
            }
            .foregroundStyle(.primary)
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

    private func glowCircle(size: CGFloat) -> some View {
        Circle()
            .fill(Color.primary.opacity(0.18))
            .frame(width: size, height: size)
            .blur(radius: 8)
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
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .trailing) {
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
                    ZStack {
                        glowCircle(size: 38)
                        Image(systemName: "speedometer")
                            .font(.system(size: 20, weight: .semibold))
                            .frame(width: 36, height: 36)
                    }
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Opcoes de playback")
                }
                .disabled(!viewModel.hasAudio)
                .tint(.primary)
                .padding(.trailing, 4)
            }
        }
    }

    @ViewBuilder
    var progressSection: some View {
        let maxDuration = max(viewModel.duration, 1)
        let remainingTime = max(maxDuration - viewModel.currentTime, 0)

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

                Text("-\(formatTime(remainingTime))")
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

    private func formatTime(_ seconds: TimeInterval) -> String {
        let value = seconds.isFinite ? max(seconds, 0) : 0
        return Self.timeFormatter.string(from: value) ?? "0:00"
    }

    private static let timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        formatter.unitsStyle = .positional
        return formatter
    }()
}

// MARK: - Previews

#if DEBUG
private enum PlayerViewPreviewFactory {
    static let sampleImage = URL(string: "https://picsum.photos/400")
    static let sampleEpisode = Episode(
        title: "Episodio 353 - El intercambio de La Cotorrisa",
        description: "Conversas sobre humor, backstage e bastidores de shows.",
        audioURL: URL(string: "https://example.com/audio.mp3"),
        duration: 3_600,
        publishedAt: .now.addingTimeInterval(-86_400),
        playbackKey: "preview-playback-key"
    )
    static let samplePodcastTitle = "La Cotorrisa"

    static func playerViewModel(
        isPlaying: Bool,
        buffering: Bool = false,
        playbackRate: Float = 1.0
    ) -> PlayerViewModel {
        let manageProgress = ManagePlaybackProgressUseCase(
            repository: MockPlaybackProgressRepository()
        )
        let playerService = PreviewAudioPlayerService(
            state: PlayerState(
                isPlaying: isPlaying,
                isBuffering: buffering,
                bufferingReason: buffering ? .insufficientBuffer : nil,
                currentTime: 120,
                duration: 3_600,
                playbackRate: playbackRate
            )
        )
        let viewModel = PlayerViewModel(
            episode: sampleEpisode,
            podcastTitle: samplePodcastTitle,
            manageProgressUseCase: manageProgress,
            playerService: playerService,
            resolvePlaybackSourceUseCase: nil
        )
        return viewModel
    }

    static func downloadsViewModel(
        downloads: [DownloadedEpisode],
        active: [DownloadProgress] = []
    ) -> DownloadsViewModel {
        let repository = PreviewDownloadsRepository(downloads: downloads)
        let service = PreviewDownloadService(active: active)
        let list = ListDownloadedEpisodesUseCase(repository: repository)
        let observe = ObserveDownloadProgressUseCase(downloadService: service)
        let delete = DeleteDownloadedEpisodeUseCase(
            downloadService: service,
            repository: repository
        )
        let enqueue = EnqueueEpisodeDownloadUseCase(
            downloadService: service,
            repository: repository
        )
        return DownloadsViewModel(
            listUseCase: list,
            observeProgressUseCase: observe,
            deleteUseCase: delete,
            enqueueUseCase: enqueue
        )
    }

    static func favoritesViewModel(marked: Bool) -> FavoritesViewModel {
        let favorites = marked ? [
            FavoriteEpisode(
                playbackKey: sampleEpisode.playbackKey,
                title: sampleEpisode.title,
                podcastTitle: samplePodcastTitle,
                podcastImageURL: sampleImage,
                summary: sampleEpisode.description,
                audioURL: sampleEpisode.audioURL,
                duration: sampleEpisode.duration,
                publishedAt: sampleEpisode.publishedAt,
                addedAt: .now
            )
        ] : []
        let repository = PreviewFavoritesRepository(favorites: favorites)
        let manage = ManageFavoriteEpisodesUseCase(repository: repository)
        return FavoritesViewModel(manageFavoritesUseCase: manage)
    }
}

private final class PreviewAudioPlayerService: AudioPlayerServiceProtocol {
    private let state: PlayerState

    init(state: PlayerState) {
        self.state = state
    }

    func observeState() -> AsyncStream<PlayerState> {
        AsyncStream { continuation in
            continuation.yield(state)
            continuation.finish()
        }
    }

    func observeEvents() -> AsyncStream<PlayerEvent> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func load(episode: Episode, podcastTitle: String) {}
    func play() {}
    func pause() {}
    func seek(to time: TimeInterval) {}
    func setRate(_ rate: Float) {}
    func teardown() {}
}

private final class PreviewDownloadsRepository: DownloadedEpisodesRepositoryProtocol {
    private var items: [DownloadedEpisode]

    init(downloads: [DownloadedEpisode]) {
        self.items = downloads
    }

    func fetch(playbackKey: String) async -> DownloadedEpisode? {
        items.first { $0.playbackKey == playbackKey }
    }

    func fetchAll() async -> [DownloadedEpisode] {
        items
    }

    func save(_ episode: DownloadedEpisode) async {
        items.removeAll { $0.playbackKey == episode.playbackKey }
        items.append(episode)
    }

    func delete(playbackKey: String) async {
        items.removeAll { $0.playbackKey == playbackKey }
    }

    func deleteExpired(before date: Date) async {}

    func totalSizeInBytes() async -> Int64 {
        items.reduce(0) { $0 + $1.fileSize }
    }
}

private final class PreviewDownloadService: EpisodeDownloadServiceProtocol {
    private let active: [DownloadProgress]

    init(active: [DownloadProgress]) {
        self.active = active
    }

    func enqueue(_ request: EpisodeDownloadRequest) async throws {}
    func cancelDownload(for playbackKey: String) async {}

    func observeProgress() -> AsyncStream<DownloadProgress> {
        AsyncStream { continuation in
            active.forEach { continuation.yield($0) }
            continuation.finish()
        }
    }

    func activeDownloads() async -> [DownloadProgress] {
        active
    }
}

private final class PreviewFavoritesRepository: FavoriteEpisodesRepositoryProtocol {
    private var items: [FavoriteEpisode]

    init(favorites: [FavoriteEpisode]) {
        self.items = favorites
    }

    func list() async -> [FavoriteEpisode] {
        items
    }

    func save(_ episode: FavoriteEpisode) async {
        items.removeAll { $0.playbackKey == episode.playbackKey }
        items.append(episode)
    }

    func remove(playbackKey: String) async {
        items.removeAll { $0.playbackKey == playbackKey }
    }

    func exists(playbackKey: String) async -> Bool {
        items.contains { $0.playbackKey == playbackKey }
    }
}

#Preview("Playing") {
    PlayerView(
        viewModel: PlayerViewPreviewFactory.playerViewModel(isPlaying: true),
        downloadsViewModel: nil,
        favoritesViewModel: PlayerViewPreviewFactory.favoritesViewModel(marked: false),
        podcastImageURL: PlayerViewPreviewFactory.sampleImage
    )
    .padding()
}

#Preview("Downloaded + Favorite") {
    let downloads = [
        DownloadedEpisode(
            playbackKey: PlayerViewPreviewFactory.sampleEpisode.playbackKey,
            title: PlayerViewPreviewFactory.sampleEpisode.title,
            podcastTitle: PlayerViewPreviewFactory.samplePodcastTitle,
            podcastImageURL: PlayerViewPreviewFactory.sampleImage,
            audioURL: PlayerViewPreviewFactory.sampleEpisode.audioURL ?? URL(fileURLWithPath: "/tmp/audio.mp3"),
            localFileURL: URL(fileURLWithPath: "/tmp/audio.mp3"),
            fileSize: 15_000_000,
            downloadedAt: .now,
            expiresAt: nil
        )
    ]

    return PlayerView(
        viewModel: PlayerViewPreviewFactory.playerViewModel(isPlaying: false),
        downloadsViewModel: PlayerViewPreviewFactory.downloadsViewModel(downloads: downloads),
        favoritesViewModel: PlayerViewPreviewFactory.favoritesViewModel(marked: true),
        podcastImageURL: PlayerViewPreviewFactory.sampleImage
    )
    .padding()
}

#Preview("Active Download") {
    let active = [
        DownloadProgress(
            playbackKey: PlayerViewPreviewFactory.sampleEpisode.playbackKey,
            state: .running,
            bytesDownloaded: 5_000_000,
            bytesExpected: 20_000_000
        )
    ]

    return PlayerView(
        viewModel: PlayerViewPreviewFactory.playerViewModel(isPlaying: false),
        downloadsViewModel: PlayerViewPreviewFactory.downloadsViewModel(downloads: [], active: active),
        favoritesViewModel: PlayerViewPreviewFactory.favoritesViewModel(marked: false),
        podcastImageURL: PlayerViewPreviewFactory.sampleImage
    )
    .padding()
}

#Preview("Sem Audio / Placeholder") {
    let episode = Episode(
        title: "Episodio sem audio",
        description: nil,
        audioURL: nil,
        duration: nil,
        publishedAt: nil,
        playbackKey: "no-audio"
    )
    let manageProgress = ManagePlaybackProgressUseCase(
        repository: MockPlaybackProgressRepository()
    )
    let playerService = PreviewAudioPlayerService(state: .idle)
    let viewModel = PlayerViewModel(
        episode: episode,
        podcastTitle: "Podcast de Teste",
        manageProgressUseCase: manageProgress,
        playerService: playerService,
        resolvePlaybackSourceUseCase: nil
    )

    return PlayerView(
        viewModel: viewModel,
        downloadsViewModel: nil,
        favoritesViewModel: PlayerViewPreviewFactory.favoritesViewModel(marked: false),
        podcastImageURL: nil
    )
    .padding()
}
#endif

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
    @Environment(FavoritesViewModel.self) private var favoritesViewModel
    let episode: Episode
    let podcastTitle: String
    let podcastImageURL: URL?

    var body: some View {
        let viewModel = playerCoordinator.prepare(
            episode: episode,
            podcastTitle: podcastTitle,
            podcastImageURL: podcastImageURL
        )
        PlayerView(
            viewModel: viewModel,
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
    let favoritesViewModel: FavoritesViewModel?
    let podcastImageURL: URL?
    @State private var isFavorite = false
    @State private var fullDescriptionText: String? = nil
    @State private var descriptionDetent: PresentationDetent = .fraction(0.33)
    @State private var backwardRotation: Double = 0
    @State private var forwardRotation: Double = 0

    init(
        viewModel: PlayerViewModel,
        favoritesViewModel: FavoritesViewModel? = nil,
        podcastImageURL: URL? = nil
    ) {
        self.viewModel = viewModel
        self.favoritesViewModel = favoritesViewModel
        self.podcastImageURL = podcastImageURL
        _isFavorite = State(initialValue: false)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            AppBackgroundView()

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
                .sheet(isPresented: .init(get: { fullDescriptionText != nil }, set: { if !$0 { fullDescriptionText = nil } })) {
                    ScrollView {
                        Text(fullDescriptionText ?? "")
                            .font(.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .textSelection(.enabled)
                            .padding()
                    }
                    .presentationDetents([.fraction(0.33), .large], selection: $descriptionDetent)
                }
            }
        }
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
        .task {
            await loadFavoriteState()
        }
    }
}

// MARK: - View Components

private extension PlayerView {
    @ViewBuilder
    var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Spacer()
                favoriteButton
            }

            if let publishedAt = viewModel.episode.publishedAt {
                Text(publishedAt, style: .date)
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.episode.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)

                Text(viewModel.podcastTitle)
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let description = viewModel.episode.description, !description.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(description)
                        .font(AppTypography.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    descriptionDetent = .fraction(0.33)
                    fullDescriptionText = description
                }
                .accessibilityAddTraits(.isButton)
            }
        }
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
                .font(AppTypography.meta)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    var controlSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                Button {
                    viewModel.skipBackward()
                    withAnimation(.easeInOut(duration: 0.35)) {
                        backwardRotation -= 360
                    }
                } label: {
                    Image(systemName: "gobackward.30")
                        .font(.system(size: 32, weight: .semibold))
                        .frame(width: 72, height: 48)
                        .rotationEffect(.degrees(backwardRotation))
                        .animation(.easeInOut(duration: 0.35), value: backwardRotation)
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
                    withAnimation(.easeInOut(duration: 0.35)) {
                        forwardRotation += 360
                    }
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.system(size: 32, weight: .semibold))
                        .frame(width: 72, height: 48)
                        .rotationEffect(.degrees(forwardRotation))
                        .animation(.easeInOut(duration: 0.35), value: forwardRotation)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Avancar 15 segundos")
                .disabled(!viewModel.hasAudio || !viewModel.isSeekable)
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                shareButton
                    .padding(.leading, 4)
            }
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
                    .accessibilityLabel("Velocidade de reproducao")
                }
                .disabled(!viewModel.hasAudio)
                .tint(.primary)
                .padding(.trailing, 4)
            }
        }
    }

    private var shareButton: some View {
        Group {
            if let shareData = shareData {
                ShareLink(
                    item: shareData.url,
                    subject: Text("Compartilhar episodio"),
                    message: Text(shareData.message)
                ) {
                    ZStack {
                        glowCircle(size: 36)
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20, weight: .semibold))
                            .frame(width: 36, height: 36)
                    }
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Compartilhar episodio")
            } else {
                Color.clear
                    .frame(width: 36, height: 36)
                    .opacity(0)
            }
        }
    }

    private var shareData: (url: URL, message: String)? {
        if let feedURL = shareFeedURL {
            let message = "Assine o podcast \(viewModel.podcastTitle) via RSS."
            return (feedURL, message)
        }

        guard let audioURL = viewModel.episode.audioURL else { return nil }
        let message = "Ouça \"\(viewModel.episode.title)\" do podcast \(viewModel.podcastTitle)."
        return (audioURL, message)
    }

    private var shareFeedURL: URL? {
        let key = viewModel.episode.playbackKey
        let prefix = "podcast:"
        guard key.hasPrefix(prefix) else { return nil }
        let remainder = key.dropFirst(prefix.count)
        guard let separatorIndex = remainder.firstIndex(of: "|") else { return nil }
        let feedString = remainder[..<separatorIndex]
        guard !feedString.isEmpty else { return nil }
        return URL(string: String(feedString))
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
                        .font(AppTypography.caption)
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
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("-\(formatTime(remainingTime))")
                    .font(AppTypography.caption)
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
            playerService: playerService
        )
        return viewModel
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

#Preview("Player (isolado) - Playing") {
    PlayerView(
        viewModel: PlayerViewPreviewFactory.playerViewModel(isPlaying: true),
        favoritesViewModel: PlayerViewPreviewFactory.favoritesViewModel(marked: false),
        podcastImageURL: PlayerViewPreviewFactory.sampleImage
    )
    .padding()
}

#Preview("Player (isolado) - Sem audio / placeholder") {
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
        playerService: playerService
    )

    return PlayerView(
        viewModel: viewModel,
        favoritesViewModel: PlayerViewPreviewFactory.favoritesViewModel(marked: false),
        podcastImageURL: nil
    )
    .padding()
}
#endif

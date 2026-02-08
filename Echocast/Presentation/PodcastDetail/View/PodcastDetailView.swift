//
//  PodcastDetailView.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 20/12/25.
//

import SwiftUI

struct PodcastDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    let viewModel: PodcastDetailViewModel

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: Spacing.space24) {
                podcastHeader
                episodesSection
            }
        }
        .navigationTitle(viewModel.podcast.title)
        .toolbarTitleDisplayMode(.large)
        .navigationDestination(for: Episode.self) { episode in
            PlayerRouteView(
                episode: episode,
                podcastTitle: viewModel.podcast.title,
                podcastImageURL: viewModel.podcast.imageURL
            )
        }
    }
}

// MARK: - View Components

private extension PodcastDetailView {

    @ViewBuilder
    var podcastHeader: some View {
        VStack(spacing: Spacing.space12) {
            PodcastArtworkView(
                imageURL: viewModel.podcast.imageURL,
                size: Size.podcastDetailArtwork,
                cornerRadius: Spacing.radius12
            )

            if let author = viewModel.podcast.author {
                Text(author)
                    .font(Typography.body)
                    .foregroundStyle(
                        Colors.text(.secondary, on: .appBackground, scheme: colorScheme)
                    )
            }

            if let description = viewModel.podcast.description {
                Text(description)
                    .font(Typography.caption)
                    .foregroundStyle(
                        Colors.text(.secondary, on: .appBackground, scheme: colorScheme)
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.top)
    }

    @ViewBuilder
    var episodesSection: some View {
        if viewModel.podcast.episodes.isEmpty {
            ContentUnavailableView(
                "Nenhum episodio",
                systemImage: SFSymbols.headphones,
                description: Text("Este podcast ainda nao possui episodios")
            )
        } else {
            List(viewModel.podcast.episodes) { episode in
                NavigationLink(value: episode) {
                    EpisodeRow(episode: episode)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

// MARK: - Episode Row

private struct EpisodeRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let episode: Episode

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.space4) {
            Text(episode.title)
                .font(Typography.title)
                .lineLimit(2)

            if let description = episode.description, !description.isEmpty {
                Text(description)
                    .font(Typography.body)
                    .foregroundStyle(
                        Colors.text(.secondary, on: .card, scheme: colorScheme)
                    )
                    .lineLimit(3)
            }

            HStack(spacing: Spacing.space8) {
                if let date = episode.publishedAt {
                    Text(date, style: .date)
                        .font(Typography.caption)
                        .foregroundStyle(
                            Colors.text(.secondary, on: .card, scheme: colorScheme)
                        )
                }

                if let duration = episode.duration {
                    Text(formatDuration(duration))
                        .font(Typography.caption)
                        .foregroundStyle(
                            Colors.text(.secondary, on: .card, scheme: colorScheme)
                        )
                }
            }
        }
        .padding(.vertical, Spacing.space4)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)min"
        }
        return "\(minutes) min"
    }
}


// MARK: - Previews

#Preview("PodcastDetail (isolado) - Com podcast") {
    NavigationStack {
        PodcastDetailView(
            viewModel: PodcastDetailViewModel(
                podcast: Podcast(
                    title: "Swift by Sundell",
                    description: "Um podcast sobre desenvolvimento Swift e iOS com dicas e entrevistas.",
                    author: "John Sundell",
                    imageURL: URL(string: "https://example.com/image.jpg"),
                    feedURL: URL(string: "https://swiftbysundell.com/feed")!,
                    episodes: [
                        Episode(title: "Episode 1: Getting Started with SwiftUI", duration: 3600, publishedAt: Date()),
                        Episode(title: "Episode 2: Advanced Combine", duration: 2700, publishedAt: Date().addingTimeInterval(-86400))
                    ]
                )
            )
        )
    }
    .environment(
        PlayerCoordinator(
            manageProgressUseCase: ManagePlaybackProgressUseCase(
                repository: MockPlaybackProgressRepository()
            ),
            playerService: MockAudioPlayerService()
        )
    )
}

#Preview("PodcastDetail (isolado) - Sem episodios") {
    NavigationStack {
        PodcastDetailView(
            viewModel: PodcastDetailViewModel(
                podcast: Podcast(
                    title: "Novo Podcast",
                    feedURL: URL(string: "https://example.com/feed")!
                )
            )
        )
    }
    .environment(
        PlayerCoordinator(
            manageProgressUseCase: ManagePlaybackProgressUseCase(
                repository: MockPlaybackProgressRepository()
            ),
            playerService: MockAudioPlayerService()
        )
    )
}

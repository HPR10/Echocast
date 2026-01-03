//
//  DownloadsView.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import SwiftUI

struct DownloadsView: View {
    let viewModel: DownloadsViewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            List {
                if !viewModel.activeDownloads.isEmpty {
                    Section("Em andamento") {
                        ForEach(viewModel.activeDownloads) { progress in
                            DownloadProgressRow(
                                progress: progress,
                                metadata: viewModel.metadata(for: progress.playbackKey)
                            )
                        }
                    }
                }

                Section("Baixados") {
                    if viewModel.downloads.isEmpty {
                        ContentUnavailableView(
                            "Nenhum download",
                            systemImage: "tray.and.arrow.down",
                            description: Text("Baixe episodios para ouvir offline.")
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(viewModel.downloads) { item in
                            NavigationLink {
                                PlayerRouteView(
                                    episode: Episode(
                                        title: item.title,
                                        audioURL: item.audioURL,
                                        playbackKey: item.playbackKey
                                    ),
                                    podcastTitle: item.podcastTitle,
                                    podcastImageURL: item.podcastImageURL
                                )
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.title)
                                        .font(.headline)
                                        .lineLimit(2)
                                    Text(item.podcastTitle)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                    Text(formatFileSize(item.fileSize))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            Task { @MainActor in
                                for index in indexSet {
                                    let item = viewModel.downloads[index]
                                    await viewModel.delete(playbackKey: item.playbackKey)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Baixados")
            .listStyle(.insetGrouped)
            .task {
                await viewModel.refresh()
                await viewModel.loadActiveDownloads()
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

    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

private struct DownloadProgressRow: View {
    let progress: DownloadProgress
    let metadata: (title: String, podcastTitle: String)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(metadata?.title ?? "Download")
                .font(.headline)
                .lineLimit(2)
            Text(metadata?.podcastTitle ?? progress.playbackKey)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if let fraction = progress.fractionCompleted {
                ProgressView(value: fraction)
            } else {
                ProgressView()
            }

            Text(progressLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var progressLabel: String {
        switch progress.state {
        case .queued:
            return "Na fila"
        case .running:
            if let fraction = progress.fractionCompleted {
                let percent = Int(fraction * 100)
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
}

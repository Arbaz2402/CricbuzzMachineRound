//
//  MovieDetailView.swift
//  CricbuzzMachineRound
//

import SwiftUI
import SDWebImageSwiftUI

struct MovieDetailView: View {
    let movieID: Int
    @StateObject private var viewModel: MovieDetailViewModel
    @Environment(\.openURL) private var openURL
    @State private var showTrailer: Bool = false
    @State private var trailerFailed: Bool = false

    init(movieID: Int) {
        self.movieID = movieID
        _viewModel = StateObject(wrappedValue: MovieDetailViewModel(id: movieID))
    }

// MARK: - Small UI helper
private struct Chip: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).imageScale(.small)
            Text(text)
        }
        .font(.footnote)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .foregroundStyle(.white)
    }
}

private func formattedRuntime(_ minutes: Int) -> String {
    let hours = minutes / 60
    let mins = minutes % 60
    if hours > 0 && mins > 0 {
        return "\(hours)h \(mins)m"
    } else if hours > 0 {
        return "\(hours)h"
    } else {
        return "\(mins)m"
    }
}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Trailer area: inline in-app YouTube player
                Group {
                    if let ytID = viewModel.youtubeVideoID {
                        ZStack {
                            if showTrailer {
                                YouTubeSDKPlayerView(videoID: ytID, autoPlay: true)
                                    .frame(height: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                // Backdrop placeholder before playing
                                if let d = viewModel.detail,
                                   let url = ImageURLBuilder.backdropURL(path: d.backdropPath) {
                                    WebImage(url: url)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Rectangle().fill(Color(.secondarySystemFill))
                                }

                                Button {
                                    trailerFailed = false
                                    withAnimation(.easeInOut) { showTrailer = true }
                                } label: {
                                    Label("Trailer", systemImage: "play.fill")
                                        .font(.headline.weight(.semibold))
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(.ultraThinMaterial, in: Capsule())
                                        .foregroundStyle(.white)
                                        .shadow(radius: 4)
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            }
                        }
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        // Always show a neutral placeholder (no text) to avoid layout jumps
                        Rectangle()
                            .fill(Color(.secondarySystemFill))
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                if let d = viewModel.detail {
                    HStack(alignment: .top, spacing: 12) {
                        if let url = ImageURLBuilder.posterURL(path: d.posterPath) {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 150)
                                .clipped()
                                .cornerRadius(10)
                        } else {
                            Rectangle()
                                .fill(Color(.secondarySystemFill))
                                .frame(width: 100, height: 150)
                                .cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(d.title).font(.title2).bold()
                            HStack(spacing: 12) {
                                if let runtime = d.runtime { Label(formattedRuntime(runtime), systemImage: "clock") }
                                if let rating = d.voteAverage { Label(String(format: "%.1f", rating), systemImage: "star.fill") }
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            if let genres = d.genres, !genres.isEmpty {
                                Text(genres.map { $0.name }.joined(separator: ", "))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button(action: { viewModel.toggleFavorite() }) {
                            Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                                .foregroundStyle(viewModel.isFavorite ? .red : .secondary)
                                .imageScale(.large)
                        }
                        .buttonStyle(.plain)
                    }

                    if let overview = d.overview, !overview.isEmpty {
                        Text("Overview").font(.headline)
                        Text(overview)
                            .foregroundStyle(.primary)
                    }
                }

                if let cast = viewModel.credits?.cast, !cast.isEmpty {
                    Text("Cast").font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(cast) { member in
                                VStack(spacing: 6) {
                                    if let url = ImageURLBuilder.posterURL(path: member.profilePath) {
                                        WebImage(url: url)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 70, height: 100)
                                            .clipped()
                                            .cornerRadius(8)
                                    } else {
                                        ZStack {
                                            Color(.secondarySystemFill)
                                            Image(systemName: "person.fill")
                                                .foregroundStyle(.secondary)
                                        }
                                        .frame(width: 70, height: 100)
                                        .cornerRadius(8)
                                    }
                                    Text(member.name)
                                        .font(.caption)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 70, height: 32, alignment: .top)
                                }
                                .frame(width: 70, alignment: .top)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let d = viewModel.detail {
                    Text(d.title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                } else {
                    EmptyView()
                }
            }
        }
        .overlay(loadingOverlay)
        .task { await viewModel.load() }
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    @ViewBuilder private var loadingOverlay: some View {
        if viewModel.isLoading && viewModel.detail == nil {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    NavigationStack { MovieDetailView(movieID: 1) }
}

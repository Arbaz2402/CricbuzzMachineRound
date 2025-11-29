//
//  MovieDetailView.swift
//  CricbuzzMachineRound
//
//  Created by Arbaz Kaladiya on 22/11/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct MovieDetailView: View {
    let movieID: Int
    @StateObject private var viewModel: MovieDetailViewModel
    @State private var showTrailer: Bool = false
    @State private var trailerFailed: Bool = false

    init(movieID: Int) {
        self.movieID = movieID
        _viewModel = StateObject(wrappedValue: MovieDetailViewModel(id: movieID))
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TrailerSection(viewModel: viewModel, showTrailer: $showTrailer, trailerFailed: trailerFailed)
                if let d = viewModel.detail {
                    HeaderSection(detail: d, isFavorite: viewModel.isFavorite, onToggleFavorite: { viewModel.toggleFavorite() })
                    if let overview = d.overview, !overview.isEmpty {
                        OverviewSection(text: overview)
                    }
                }
                CastSection(credits: viewModel.credits)
            }
            .padding()
            .refreshable { await viewModel.load() }
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
        .onChange(of: viewModel.videos) { _ in
            if viewModel.youtubeVideoID == nil {
                trailerFailed = false
                Task {
                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                    if viewModel.youtubeVideoID == nil { trailerFailed = true }
                }
            } else {
                trailerFailed = false
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    @ViewBuilder private var loadingOverlay: some View {
        if viewModel.isLoading && viewModel.detail == nil {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct TrailerSection: View {
    @ObservedObject var viewModel: MovieDetailViewModel
    @Binding var showTrailer: Bool
    var trailerFailed: Bool
    var body: some View {
        Group {
            if let ytID = viewModel.youtubeVideoID {
                ZStack {
                    if showTrailer {
                        YouTubeSDKPlayerView(videoID: ytID, autoPlay: true)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        if let detail = viewModel.detail,
                           let url = ImageURLBuilder.backdropImageURL(path: detail.backdropPath) {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFill()
                        } else {
                            ZStack {
                                Color(.secondarySystemFill)
                                Image(systemName: "film")
                                    .font(.system(size: 40, weight: .regular))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Button {
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
                ZStack {
                    Color(.secondarySystemFill)
                    VStack(spacing: 8) {
                        Image(systemName: "film")
                            .font(.system(size: 40, weight: .regular))
                            .foregroundStyle(.secondary)
                        if trailerFailed {
                            Text("Trailer not available")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

private struct HeaderSection: View {
    let detail: MovieDetail
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let url = ImageURLBuilder.posterURL(path: detail.posterPath) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 150)
                    .clipped()
                    .cornerRadius(10)
            } else {
                ZStack {
                    Color(.secondarySystemFill)
                    Image(systemName: "film")
                        .foregroundStyle(.secondary)
                }
                .frame(width: 100, height: 150)
                .cornerRadius(10)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(detail.title).font(.title2).bold()
                HStack(spacing: 12) {
                    if let runtime = detail.runtime {
                        Label(RuntimeFormatter.format(runtime), systemImage: "clock")
                    } else {
                        Label("--", systemImage: "clock")
                    }
                    if let rating = detail.voteAverage {
                        Label(String(format: "%.1f", rating), systemImage: "star.fill")
                    } else {
                        Label("--", systemImage: "star.fill")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                Group {
                    if let genres = detail.genres, !genres.isEmpty {
                        Text(genres.map { $0.name }.joined(separator: ", "))
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.secondarySystemFill))
                            .frame(height: 12)
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(isFavorite ? .red : .secondary)
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct OverviewSection: View {
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Overview").font(.headline)
            Text(text).foregroundStyle(.primary)
        }
    }
}

private struct CastSection: View {
    let credits: Credits?
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cast").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    if let cast = credits?.cast, !cast.isEmpty {
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
                    } else {
                        ForEach(0..<8, id: \.self) { _ in
                            VStack(spacing: 6) {
                                ZStack {
                                    Color(.secondarySystemFill)
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 70, height: 100)
                                .cornerRadius(8)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(.secondarySystemFill))
                                    .frame(width: 70, height: 14)
                            }
                            .frame(width: 70, alignment: .top)
                        }
                    }
                }
            }
        }
    }
}
#Preview {
    NavigationStack { MovieDetailView(movieID: 1) }
}

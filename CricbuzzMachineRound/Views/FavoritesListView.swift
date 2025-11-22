//
//  FavoritesListView.swift
//  CricbuzzMachineRound
//
//  Created by Arbaz Kaladiya on 22/11/25.
//

import SwiftUI

struct FavoritesListView: View {
    @ObservedObject var viewModel: MovieListViewModel

    private var favoriteMovies: [Movie] {
        viewModel.movies.filter { viewModel.favoriteIDs.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if favoriteMovies.isEmpty {
                    EmptyStateView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 40)
                } else {
                    ForEach(favoriteMovies) { movie in
                        FavoriteRowLink(movie: movie, viewModel: viewModel)
                    }
                }
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("No favorites yet").font(.headline)
            Text("Tap the heart on any movie to add it here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct FavoriteRowLink: View {
    let movie: Movie
    @ObservedObject var viewModel: MovieListViewModel
    var body: some View {
        NavigationLink(destination: MovieDetailView(movieID: movie.id)) {
            MovieRowView(
                movie: movie,
                isFavorite: true,
                durationMinutes: viewModel.duration(for: movie.id),
                onFavoriteToggle: { viewModel.toggleFavorite(id: movie.id) }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .task { await viewModel.loadDurationIfNeeded(for: movie) }
    }
}

#Preview {
    NavigationStack {
        FavoritesListView(viewModel: MovieListViewModel())
    }
}


//
//  MovieListView.swift
//  CricbuzzMachineRound
//

import SwiftUI

struct MovieListView: View {
    @StateObject private var viewModel = MovieListViewModel()
    
    private var displayedMovies: [Movie] {
        if viewModel.showFavoritesOnly {
            return viewModel.movies.filter { viewModel.favoriteIDs.contains($0.id) }
        }
        return viewModel.movies
    }

    var body: some View {
        NavigationStack {
            Group {
                if let error = viewModel.errorMessage, displayedMovies.isEmpty {
                    VStack(spacing: 12) {
                        Text("Something went wrong").font(.headline)
                        Text(error).font(.subheadline).foregroundStyle(.secondary)
                        Button("Retry") { Task { await viewModel.loadPopular() } }
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            if viewModel.isLoading && displayedMovies.isEmpty {
                                ForEach(0..<6, id: \.self) { _ in
                                    MovieRowSkeleton()
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                }
                            } else {
                                ForEach(displayedMovies) { movie in
                                    NavigationLink(value: movie) {
                                        MovieRowView(
                                            movie: movie,
                                            isFavorite: viewModel.favoriteIDs.contains(movie.id),
                                            onFavoriteToggle: { viewModel.toggleFavorite(id: movie.id) }
                                        )
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                    }
                                    .task { await viewModel.loadMoreIfNeeded(currentItem: movie) }
                                }
                                if viewModel.isLoadingMore {
                                    HStack { Spacer(); ProgressView().padding(); Spacer() }
                                }
                            }
                        }
                    }
                    .refreshable { await refresh() }
                }
            }
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movieID: movie.id)
            }
            .navigationTitle("")
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Popular Movies")
                        .font(.title.bold())
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.easeInOut) { viewModel.showFavoritesOnly.toggle() }
                    } label: {
                        Image(systemName: viewModel.showFavoritesOnly ? "heart.fill" : "heart")
                            .foregroundStyle(viewModel.showFavoritesOnly ? .red : .primary)
                            .imageScale(.large)
                            .accessibilityLabel(viewModel.showFavoritesOnly ? "Showing Favorites" : "Show Favorites")
                    }
                }
            }
            .searchable(text: Binding(
                get: { viewModel.searchText },
                set: { newValue in
                    viewModel.searchText = newValue
                }
            ), placement: .navigationBarDrawer(displayMode: .always))
            // Debounced in ViewModel; no need for extra triggers here
            .task { await viewModel.loadPopular() }
            .background(Color(.systemBackground).ignoresSafeArea())
        }
    }

    private func refresh() async {
        if viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            await viewModel.loadPopular()
        } else {
            await viewModel.search()
        }
    }
}

// MARK: - Lightweight Skeleton Row
private struct MovieRowSkeleton: View {
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemFill))
                .frame(width: 110, height: 165)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 6).fill(Color(.secondarySystemFill)).frame(height: 18)
                RoundedRectangle(cornerRadius: 6).fill(Color(.secondarySystemFill)).frame(height: 14)
                RoundedRectangle(cornerRadius: 6).fill(Color(.secondarySystemFill)).frame(height: 14)
                HStack(spacing: 6) {
                    Circle().fill(Color(.secondarySystemFill)).frame(width: 12, height: 12)
                    RoundedRectangle(cornerRadius: 6).fill(Color(.secondarySystemFill)).frame(width: 40, height: 12)
                    Circle().fill(Color(.secondarySystemFill)).frame(width: 12, height: 12)
                    RoundedRectangle(cornerRadius: 6).fill(Color(.secondarySystemFill)).frame(width: 80, height: 12)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    MovieListView()
}

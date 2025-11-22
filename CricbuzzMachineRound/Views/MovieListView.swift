//
//  MovieListView.swift
//  CricbuzzMachineRound
//

import SwiftUI

struct MovieListView: View {
    @StateObject private var viewModel = MovieListViewModel()
    @State private var didScrollToTopForActiveSearch = false

    var body: some View {
        NavigationStack {
            Group {
                if let error = viewModel.errorMessage, viewModel.movies.isEmpty {
                    VStack(spacing: 12) {
                        Text("Something went wrong").font(.headline)
                        Text(error).font(.subheadline).foregroundStyle(.secondary)
                        Button("Retry") { Task { await viewModel.loadPopular() } }
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                // Anchor for scrolling to top when search/query changes
                                Color.clear.frame(height: 0).id("top")
                                if viewModel.isLoading && viewModel.movies.isEmpty {
                                    ForEach(0..<6, id: \.self) { _ in
                                        MovieRowSkeleton()
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                    }
                                } else {
                                    ForEach(viewModel.movies) { movie in
                                        NavigationLink(value: movie) {
                                            MovieRowView(
                                                movie: movie,
                                                isFavorite: viewModel.favoriteIDs.contains(movie.id),
                                                runtimeMinutes: viewModel.runtime(for: movie.id),
                                                onFavoriteToggle: { viewModel.toggleFavorite(id: movie.id) }
                                            )
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                        }
                                        .task {
                                            await viewModel.loadMoreIfNeeded(currentItem: movie)
                                            await viewModel.loadRuntimeIfNeeded(for: movie)
                                        }
                                    }
                                    if viewModel.isLoadingMore {
                                        HStack { Spacer(); ProgressView().padding(); Spacer() }
                                    }
                                }
                            }
                            .refreshable { await refresh() }
                            // When the search text changes, scroll back to the top anchor
                            .onChange(of: viewModel.searchText) { newValue in
                                if newValue.isEmpty {
                                    // Reset for next search, but do not scroll when canceling
                                    didScrollToTopForActiveSearch = false
                                } else if !didScrollToTopForActiveSearch {
                                    // Scroll to top only once at the start of a search
                                    withAnimation { proxy.scrollTo("top", anchor: .top) }
                                    didScrollToTopForActiveSearch = true
                                }
                            }
                        }
                    }
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
                    Text("Movies")
                        .font(.title.bold())
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        FavoritesListView(viewModel: viewModel)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                            Text("Favorites")
                        }
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
            .task {
                // Only perform initial load when there is no data yet.
                // This prevents search results from being overwritten when returning from detail.
                if viewModel.movies.isEmpty {
                    await viewModel.loadPopular()
                }
            }
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

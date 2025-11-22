//
//  MovieListView.swift
//  CricbuzzMachineRound
//
//  Created by Arbaz Kaladiya on 22/11/25.
//

import SwiftUI

struct MovieListView: View {
    @StateObject private var viewModel = MovieListViewModel()
    @State private var didScrollToTopForActiveSearch = false
    @State private var lastScrolledQuery: String = ""
    @State private var lastNonSearchAnchorID: Int?
    @State private var restoreAnchorID: Int?

    var body: some View {
        NavigationStack {
            Group {
                if let error = viewModel.errorMessage, viewModel.movies.isEmpty {
                    ErrorStateView(message: error) { Task { await viewModel.loadPopular() } }
                } else {
                    ListContent(
                        viewModel: viewModel,
                        didScrollToTopForActiveSearch: $didScrollToTopForActiveSearch,
                        lastScrolledQuery: $lastScrolledQuery,
                        lastNonSearchAnchorID: $lastNonSearchAnchorID,
                        restoreAnchorID: $restoreAnchorID,
                        refresh: refresh
                    )
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
                        Text("Favorites")
                    }
                }
            }
            .searchable(text: Binding(
                get: { viewModel.searchText },
                set: { newValue in viewModel.searchText = newValue }
            ), placement: .navigationBarDrawer(displayMode: .always))
            .task {
                if viewModel.movies.isEmpty { await viewModel.loadPopular() }
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

private struct ErrorStateView: View {
    let message: String
    let retry: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            Text("Something went wrong").font(.headline)
            Text(message).font(.subheadline).foregroundStyle(.secondary)
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ListContent: View {
    @ObservedObject var viewModel: MovieListViewModel
    @Binding var didScrollToTopForActiveSearch: Bool
    @Binding var lastScrolledQuery: String
    @Binding var lastNonSearchAnchorID: Int?
    @Binding var restoreAnchorID: Int?
    let refresh: () async -> Void
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
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
                            .onAppear {
                                if viewModel.searchText.isEmpty {
                                    lastNonSearchAnchorID = movie.id
                                }
                            }
                        }
                        if viewModel.isLoadingMore {
                            HStack { Spacer(); ProgressView().padding(); Spacer() }
                        }
                    }
                }
                .refreshable { await refresh() }
                .onChange(of: viewModel.movies) { _ in
                    let query = viewModel.searchText
                    guard !query.isEmpty else { return }
                    if lastScrolledQuery != query {
                        withAnimation { proxy.scrollTo("top", anchor: .top) }
                        lastScrolledQuery = query
                    }
                }
                .onChange(of: viewModel.searchText) { newValue in
                    if newValue.isEmpty {
                        didScrollToTopForActiveSearch = false
                        lastScrolledQuery = ""
                        if let id = restoreAnchorID {
                            withAnimation { proxy.scrollTo(id, anchor: .top) }
                            restoreAnchorID = nil
                        }
                    } else if restoreAnchorID == nil {
                        restoreAnchorID = lastNonSearchAnchorID
                    }
                }
            }
        }
    }
}

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

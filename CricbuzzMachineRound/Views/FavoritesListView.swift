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
                    VStack(spacing: 8) {
                        Text("No favorites yet")
                            .font(.headline)
                        Text("Tap the heart on any movie to add it here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 40)
                } else {
                    ForEach(favoriteMovies) { movie in
                        NavigationLink(destination: MovieDetailView(movieID: movie.id)) {
                            MovieRowView(
                                movie: movie,
                                isFavorite: true,
                                runtimeMinutes: viewModel.runtime(for: movie.id),
                                onFavoriteToggle: { viewModel.toggleFavorite(id: movie.id) }
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .task {
                            await viewModel.loadRuntimeIfNeeded(for: movie)
                        }
                    }
                }
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}

#Preview {
    NavigationStack {
        FavoritesListView(viewModel: MovieListViewModel())
    }
}


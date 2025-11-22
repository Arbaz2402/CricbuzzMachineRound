//
//  MovieListViewModel.swift
//  CricbuzzMachineRound
//
//  Created by Arbaz Kaladiya on 22/11/25.
//

import Foundation
import Combine

@MainActor
final class MovieListViewModel: ObservableObject {
    @Published private(set) var movies: [Movie] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published var searchText: String = ""
    @Published private(set) var errorMessage: String?
    @Published private(set) var favoriteIDs: Set<Int> = []
    @Published private(set) var runtimes: [Int: Int] = [:]

    private let moviesService: MovieServicing
    private let favorites: FavoritesStoring
    private var searchCancellable: AnyCancellable?
    private var favoritesObserver: Any?

    // Pagination state
    private var currentPage: Int = 1
    private var totalPages: Int = 1
    private var lastQuery: String = ""

    init(moviesService: MovieServicing = MovieService(), favorites: FavoritesStoring = FavoritesStore.shared) {
        self.moviesService = moviesService
        self.favorites = favorites
        self.favoriteIDs = favorites.all()
        // Debounce search text updates to keep UI smooth
        searchCancellable = $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self else { return }
                Task { await self.handleDebouncedSearch(text: value) }
            }

        // Observe favorites changes to stay in sync with detail screen
        favoritesObserver = NotificationCenter.default.addObserver(forName: .favoritesChanged, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            self.favoriteIDs = self.favorites.all()
        }
    }

    deinit {
        if let obs = favoritesObserver { NotificationCenter.default.removeObserver(obs) }
    }

    func loadPopular() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            let page = try await moviesService.popular(page: 1)
            currentPage = page.page
            totalPages = page.totalPages
            lastQuery = ""
            movies = page.results
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func search() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { await loadPopular(); return }
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            let page = try await moviesService.search(query: query, page: 1)
            currentPage = page.page
            totalPages = page.totalPages
            lastQuery = query
            movies = page.results
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func toggleFavorite(id: Int) {
        favorites.toggleFavorite(id: id)
        favoriteIDs = favorites.all()
    }
    func runtime(for movieID: Int) -> Int? {
        runtimes[movieID]
    }

    func loadRuntimeIfNeeded(for movie: Movie) async {
        guard runtimes[movie.id] == nil else { return }
        do {
            let detail = try await moviesService.detail(id: movie.id)
            if let rt = detail.runtime {
                runtimes[movie.id] = rt
            }
        } catch {
            // For list display, silently ignore runtime failures
        }
    }

    private func handleDebouncedSearch(text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            await loadPopular()
        } else {
            await search()
        }
    }

    // Pagination
    func loadMoreIfNeeded(currentItem item: Movie?) async {
        guard !isLoading, !isLoadingMore else { return }
        guard currentPage < totalPages else { return }
        guard let item else { return }
        // Trigger when we approach the end of the list
        let thresholdIndex = max(movies.count - 5, 0)
        if let index = movies.firstIndex(where: { $0.id == item.id }), index >= thresholdIndex {
            await loadNextPage()
        }
    }

    private func loadNextPage() async {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            if lastQuery.isEmpty {
                let page = try await moviesService.popular(page: currentPage + 1)
                currentPage = page.page
                totalPages = page.totalPages
                movies.append(contentsOf: page.results)
            } else {
                let page = try await moviesService.search(query: lastQuery, page: currentPage + 1)
                currentPage = page.page
                totalPages = page.totalPages
                movies.append(contentsOf: page.results)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

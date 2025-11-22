//
//  MovieDetailViewModel.swift
//  CricbuzzMachineRound
//
//  Handles movie details, videos, and cast
//

import Foundation
import Combine

@MainActor
final class MovieDetailViewModel: ObservableObject {
    @Published private(set) var detail: MovieDetail?
    @Published private(set) var videos: [Video] = []
    @Published private(set) var credits: Credits?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isFavorite: Bool = false

    private let id: Int
    private let service: MovieServicing
    private let favorites: FavoritesStoring
    private var favoritesObserver: Any?

    init(id: Int,
         service: MovieServicing = MovieService(),
         favorites: FavoritesStoring = FavoritesStore.shared) {
        self.id = id
        self.service = service
        self.favorites = favorites
        self.isFavorite = favorites.isFavorite(id: id)
        self.favoritesObserver = NotificationCenter.default.addObserver(forName: .favoritesChanged, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            self.isFavorite = self.favorites.isFavorite(id: self.id)
        }
    }

    deinit {
        if let obs = favoritesObserver { NotificationCenter.default.removeObserver(obs) }
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            async let d: MovieDetail = service.detail(id: id)
            async let v: VideoPage = service.videos(id: id)
            async let c: Credits = service.credits(id: id)
            self.detail = try await d
            let videosPage = try await v
            self.videos = videosPage.results
            self.credits = try await c
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func toggleFavorite() {
        favorites.toggleFavorite(id: id)
        isFavorite = favorites.isFavorite(id: id)
    }

    var trailerURL: URL? {
        guard let yt = videos.first(where: { $0.site.lowercased() == "youtube" && $0.type.lowercased() == "trailer" }) else { return nil }
        return URL(string: "https://www.youtube.com/embed/\(yt.key)?playsinline=1&modestbranding=1&rel=0")
    }

    // For native AVPlayer playback. TMDb usually provides YouTube keys, which are not natively playable.
    // Return nil by default; if you later have a direct MP4/HLS URL from another provider, return it here.
    var nativeTrailerURL: URL? {
        // Example hook: if TMDb ever returns a directly playable URL in future.
        // For now, keep nil to use external YouTube fallback in the view.
        return nil
    }

    // YouTube embed support (in-app playback)
    var youtubeVideoID: String? {
        // Only use official YouTube trailers, ignore teasers/featurettes/BTS
        return videos.first(where: {
            $0.site.lowercased() == "youtube" && $0.type.lowercased() == "trailer"
        })?.key
    }
}

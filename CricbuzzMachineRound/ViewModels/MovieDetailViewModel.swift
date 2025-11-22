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
            // Load critical content (detail + videos). These drive the UI.
            async let d: MovieDetail = service.detail(id: id)
            async let v: VideoPage = service.videos(id: id)
            self.detail = try await d
            let videosPage = try await v
            self.videos = videosPage.results
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false

        // Load credits independently; if it fails, retry silently in background
        await loadCreditsWithRetry()
    }

    private func loadCreditsWithRetry(maxAttempts: Int = 3, baseDelay: UInt64 = 300_000_000) async {
        // Try once immediately
        do {
            self.credits = try await service.credits(id: id)
            return
        } catch {
            // fall through to retries
        }

        for attempt in 1...maxAttempts {
            do {
                self.credits = try await service.credits(id: id)
                return
            } catch {
                // exponential backoff: 0.3s, 0.6s, 1.2s, ...
                let delay = baseDelay * (1 << (attempt - 1))
                try? await Task.sleep(nanoseconds: delay)
            }
        }
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

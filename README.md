# TMDb Movie Browser – Cricbuzz Machine Round

SwiftUI + MVVM movie app built for the Cricbuzz machine coding round. 

The app uses **The Movie Database (TMDb)** APIs to:

- Browse **popular movies**
- View a **detail screen** with trailer, overview, genres, cast, runtime, rating
- **Search** movies by title
- Mark movies as **favorites** (persisted across launches)
- Play trailers **in‑app** using the YouTube iOS Player Helper SDK
---

## App Preview

<table>
  <tr>
    <td align="center"><img src="https://github.com/user-attachments/assets/03c6a0ce-742e-47aa-8bdb-f59038e44b96" alt="Screenshot 1" width="200"/></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/2e580a19-308c-4283-a299-b2ac344df7a9" alt="Screenshot 2" width="200"/></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/288be046-5031-41d4-9477-4c8dfc0a63f1" alt="Screenshot 3" width="200"/></td>
  </tr>
  <tr>
    <td align="center"><img src="https://github.com/user-attachments/assets/af367fb7-ce8e-4655-b605-6796a95cbf2e" alt="Screenshot 4" width="200"/></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/9452c030-7b3e-4a15-8a27-7ee695107e8a" alt="Screenshot 5" width="200"/></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/4cd457c2-c978-4caf-ad60-84433cdf7548" alt="Screenshot 6" width="200"/></td>
  </tr>
</table>

---

## 1. Setup

### 1.1 Requirements

- Xcode 15+
- iOS 17+ simulator or device
- Swift 5.9+
- A **TMDb API key** (v3 auth)

### 1.2 TMDb API key

1. Create an account at https://www.themoviedb.org and generate an API key (v3).
2. Open `CricbuzzMachineRound/Utils/APIConfig.swift`.
3. Set your TMDb key:

```swift
final class APIConfig {
    static let shared = APIConfig()
    var apiKey: String = "YOUR_TMDB_API_KEY" // <- replace

    let baseURL = URL(string: "https://api.themoviedb.org/3")!
    let imagesBaseURL = URL(string: "https://image.tmdb.org/t/p")!
    let defaultLanguage = "en-IN"
    let defaultImageSize = "w500"
}
```

The networking layer automatically appends `api_key` and `language` to all requests.

### 1.3 Dependencies (Swift Package Manager)

The project uses SPM only – no manual framework setup required. On first build, Xcode will fetch:

- **SDWebImageSwiftUI**  
  `https://github.com/SDWebImage/SDWebImageSwiftUI`  
  Used for efficient image loading, caching, and smooth placeholders for posters/backdrops/cast images.

- **YouTube iOS Player Helper (YouTubeiOSPlayerHelper)**  
  `https://github.com/youtube/youtube-ios-player-helper`  
  Provides `YTPlayerView`, which is wrapped in `YouTubeSDKPlayerView` for in‑app trailer playback using YouTube keys from TMDb.

Both packages are already added to the Xcode project as **Package Dependencies**. When the project is opened and built, Xcode will automatically resolve and download them.

### 1.4 Build & Run

1. Clone the repository.
2. Open `CricbuzzMachineRound.xcodeproj` in Xcode.
3. Ensure an iOS Simulator or device is selected (iOS 17+ recommended).
4. Press **Run** (⌘ + R).

On first build, Xcode will:

- Download SPM dependencies
- Compile the app
- Launch directly into the **Home (Popular Movies)** screen

---

## 2. Architecture & Project Structure

The app follows a **clean MVVM** structure with thin views and test‑friendly view models.

- `App/` – App entry point and root navigation.
- `Services/` – TMDb endpoints via `MovieService`, request plumbing in `NetworkService`.
- `Models/` – TMDb models (`Movie`, `MovieDetail`, `VideoPage`, `Credits`, etc.).
- `ViewModels/` – `MovieListViewModel`, `MovieDetailViewModel`, favorites sync.
- `Views/` – SwiftUI screens/components (`MovieListView`, `MovieRowView`, `MovieDetailView`, `FavoritesListView`).
- `Utils/` – `APIConfig`, `ImageURLBuilder`, `FavoritesStore`, `YouTubeSDKPlayerView`, `Formatters`.

Key design points:

- **NetworkService** is reusable and appends TMDb query params in one place.
- **MovieService** exposes typed TMDb endpoints (popular, detail, search, credits, videos).
- **ViewModels** own async loading, pagination, debounced search, and favorite state.
- **Views** are mostly stateless and react to `@Published` properties.

---

## 3. Implemented Features

### 3.1 Home – Popular Movies List

- Fetches popular movies from:

  `GET /movie/popular?page={page}`

- Each row (`MovieRowView`) shows:
  - Poster (cached via SDWebImageSwiftUI)
  - Title (2 lines, leading aligned)
  - Short overview (2 lines, fixed height to avoid layout jumps)
  - Rating (star icon + numeric)
  - Release date
  - Favorite heart button overlapping the poster’s bottom‑right corner

- **Pagination**: Infinite scroll using `loadMoreIfNeeded` in `MovieListViewModel`.
- **Favorites**: Heart toggles call a shared `FavoritesStore` and instantly update UI.
- **State restore**: When you cancel a search, the list restores to your pre‑search position.

### 3.2 Movie Detail Screen

When you tap a movie, the app pushes `MovieDetailView`, which shows:

- **Inline trailer player (top of screen)**
  - TMDb videos fetched from:

    `GET /movie/{movie_id}/videos`

  - Filtered to **`site == "YouTube"` AND `type == "Trailer"`**.
  - Uses `YouTubeSDKPlayerView` (SwiftUI wrapper around `YTPlayerView`) for in‑app playback.
  - Initial state: backdrop image with a centered `Trailer` button.
  - After tapping, the inline player replaces the backdrop and starts playing.
  - Native YouTube controls (including fullscreen) are available inside the player.

- **Header section**
  - Poster (WebImage with smooth placeholder)
  - Title
  - Runtime formatted as `2h 22m` instead of raw minutes
  - Average rating (star icon + numeric value)
  - Genres (comma‑separated)
  - Favorite toggle synced with home screen.

- **Overview**
  - Section title + full movie overview text.

- **Cast**
  - Horizontal list of cast members from:

    `GET /movie/{movie_id}/credits`

  - Each item:
    - Profile image (WebImage with person placeholder if missing/failed)
    - Name with 2‑line wrap, fixed height for consistent alignment.

### 3.3 Search

- Search bar on Home screen filters movies using:

  `GET /search/movie?query={query}&page={page}`

- **Debounced input** in `MovieListViewModel` to avoid hammering the API.
- Cancels in‑flight search requests when the query changes.
- Paginates results. Only scrolls to top after new results arrive. Canceling search restores prior scroll position.

### 3.4 Favorites

- Users can favorite/unfavorite from both:
  - Home rows
  - Detail header

- Backed by a shared `FavoritesStore` that:
  - Persists favorite IDs (e.g., via `UserDefaults`).
  - Broadcasts changes via `NotificationCenter`.
  - Keeps Home and Detail screens in sync in real time.

---

## 4. Assumptions

- TMDb **v3** APIs are used with JSON responses.
- Only **YouTube trailers** are used for video playback:
  - `site == "YouTube"`
  - `type == "Trailer"`
- Other video types from TMDb (Teaser, Featurette, Behind the Scenes) are intentionally ignored.
- Network errors are surfaced as simple textual error messages; a full retry UI is not implemented.
- The app targets portrait orientation for the main flows (landscape not specifically optimized).
- The YouTube iOS Player Helper SDK is acceptable in the assignment (no custom OAuth or advanced YouTube APIs are required).

---

## 5. Known Limitations & Possible Improvements

- **YouTube trailer availability**
  - TMDb sometimes returns videos that are not embeddable or are region/provider restricted.
  - In such cases, playback may fail even though all client‑side configuration is correct.

- **Offline behavior**
  - No explicit offline mode; the app relies on network connectivity.
  - SDWebImage’s disk cache helps for images that were previously loaded, but JSON data is not cached.

- **Tests**
  - Included unit tests for `MovieService` (all endpoints via URLProtocol stub) and `RuntimeFormatter`.
  - More can be added (VM retries, negative paths, UI tests).

- **Accessibility & Localization**
  - Basic Dynamic Type support comes from SwiftUI, but labels/hit targets can be further tuned.
  - Text is currently English‑only; TMDb `language` parameter is set to `en-US` by default.

---

## 6. How to Read / Extend the Code

- Start with **`MovieListView`** and **`MovieListViewModel`** to understand the home flow, search, and pagination.
- Then open **`MovieDetailView`** and **`MovieDetailViewModel`** to see how details, trailers, and cast are loaded.
- Look at **`MovieService`** to see how TMDb endpoints are modeled in one place.
- `YouTubeSDKPlayerView` in **`Utils/`** shows how `YTPlayerView` is wrapped for SwiftUI and configured for in‑app playback.

The code is intentionally structured and commented to be readable in a short interview review window, while still demonstrating real‑world patterns: MVVM, async/await networking, debounced search, favorites persistence, and in‑app media playback.

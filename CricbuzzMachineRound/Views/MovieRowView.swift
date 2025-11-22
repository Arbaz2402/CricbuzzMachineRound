//
//  MovieRowView.swift
//  CricbuzzMachineRound
//
//  Created by Arbaz Kaladiya on 22/11/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct MovieRowView: View {
    let movie: Movie
    let isFavorite: Bool
    let runtimeMinutes: Int?
    let onFavoriteToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                PosterView(path: movie.posterPath)
                FavoriteBadge(isFavorite: isFavorite, onTap: onFavoriteToggle)
            }
            InfoSection(movie: movie, runtimeMinutes: runtimeMinutes)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
        }
        .tint(.primary)
        .contentShape(Rectangle())
        .padding(.vertical, 6)
    }
}

private struct PosterView: View {
    let path: String?
    var body: some View {
        Group {
            if let url = ImageURLBuilder.posterURL(path: path) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(.secondarySystemFill)
            }
        }
        .frame(width: 110, height: 165)
        .clipped()
        .cornerRadius(10)
    }
}

private struct FavoriteBadge: View {
    let isFavorite: Bool
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundStyle(isFavorite ? .red : .white)
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
                .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 2)
        }
        .padding(0)
        .offset(x: 8, y: 8)
        .buttonStyle(.plain)
    }
}

private struct InfoSection: View {
    let movie: Movie
    let runtimeMinutes: Int?
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(movie.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
            if let overview = movie.overview, !overview.isEmpty {
                Text(overview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 6) {
                if let rating = movie.voteAverage {
                    Image(systemName: "star.fill").foregroundStyle(.yellow)
                    Text(String(format: "%.1f", rating))
                }
                if let date = movie.releaseDate, !date.isEmpty {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text(date)
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption)
            if let runtime = runtimeMinutes {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text(RuntimeFormatter.format(runtime))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
    }
}

#Preview {
    MovieRowView(movie: .init(id: 1, title: "The Batman", overview: "Vengeance.", posterPath: nil, backdropPath: nil, voteAverage: 7.8, releaseDate: "2022-03-04"), isFavorite: true, runtimeMinutes: 30, onFavoriteToggle: {})
        .padding()
}

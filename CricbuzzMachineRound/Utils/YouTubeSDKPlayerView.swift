//
//  YouTubeSDKPlayerView.swift
//  CricbuzzMachineRound
//
//  Created by Arbaz Kaladiya on 22/11/25.
//

import SwiftUI
import YouTubeiOSPlayerHelper

struct YouTubeSDKPlayerView: UIViewRepresentable {
    let videoID: String
    var autoPlay: Bool = false

    final class Coordinator: NSObject, YTPlayerViewDelegate {
        var parent: YouTubeSDKPlayerView

        init(parent: YouTubeSDKPlayerView) {
            self.parent = parent
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> YTPlayerView {
        let player = YTPlayerView()
        player.delegate = context.coordinator
        player.backgroundColor = .black
        player.clipsToBounds = true
        return player
    }

    func updateUIView(_ uiView: YTPlayerView, context: Context) {
        let playerVars: [String: Any] = [
            "playsinline": 1,            // play inside app, not full-screen YouTube UI
            "modestbranding": 1,
            "rel": 0,
            "autoplay": autoPlay ? 1 : 0,
            "controls": 1               // native YouTube controls
        ]

        // Load the requested video ID (simple version; can be optimized later)
        uiView.load(withVideoId: videoID, playerVars: playerVars)
    }
}

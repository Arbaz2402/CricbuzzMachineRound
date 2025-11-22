//
//  YouTubePlayerView.swift
//  CricbuzzMachineRound
//
//  Lightweight YouTube embed using WKWebView + IFrame API (no third-party libs)
//

import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    let videoID: String
    var onFinish: (() -> Void)? = nil
    var onError: (() -> Void)? = nil

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: YouTubePlayerView

        init(parent: YouTubePlayerView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.onFinish?()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.onError?()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.onError?()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Allow inline playback inside the app
        config.allowsInlineMediaPlayback = true
        // Allow autoplay when permitted by the page
        config.mediaTypesRequiringUserActionForPlayback = []
        // Ensure JavaScript is enabled
        config.preferences.javaScriptEnabled = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = true
        webView.backgroundColor = .black
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Use official YouTube embed URL for in-app players
        guard let url = URL(string: "https://www.youtube.com/embed/\(videoID)?playsinline=1&modestbranding=1&rel=0") else { return }
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }
}

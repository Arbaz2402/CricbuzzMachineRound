//
//  WebView.swift
//  CricbuzzMachineRound
//
//  Minimal WKWebView wrapper for trailer playback (YouTube)
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL?

    func makeUIView(context: Context) -> WKWebView { WKWebView() }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url else { return }
        if uiView.url != url { uiView.load(URLRequest(url: url)) }
    }
}

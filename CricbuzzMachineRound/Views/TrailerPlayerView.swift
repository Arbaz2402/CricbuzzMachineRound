//
//  TrailerPlayerView.swift
//  CricbuzzMachineRound
//
//  Native SwiftUI + AVPlayer trailer player with basic controls
//

import SwiftUI
import AVKit

struct TrailerPlayerView: View {
    let url: URL
    var onDismiss: (() -> Void)?

    @State private var player: AVPlayer = AVPlayer()
    @State private var isPlaying: Bool = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0

    @State private var timeObserverToken: Any?

    var body: some View {
        VStack(spacing: 8) {
            VideoPlayer(player: player)
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onAppear {
                    let item = AVPlayerItem(url: url)
                    player.replaceCurrentItem(with: item)
                    observeDuration(item: item)
                    addPeriodicTimeObserver()
                }
                .onDisappear {
                    removePeriodicTimeObserver()
                    player.pause()
                }

            // Scrubber
            VStack(spacing: 4) {
                Slider(value: Binding(
                    get: { currentTime },
                    set: { newValue in
                        currentTime = newValue
                        let time = CMTime(seconds: newValue, preferredTimescale: 600)
                        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
                    }
                ), in: 0...(duration > 0 ? duration : 1))

                HStack {
                    Text(formatTime(currentTime)).font(.caption).monospacedDigit()
                    Spacer()
                    Text(formatTime(duration)).font(.caption).monospacedDigit()
                }
            }

            // Controls
            HStack(spacing: 24) {
                Button { seek(by: -30) } label: {
                    Image(systemName: "gobackward.30").imageScale(.large)
                }
                Button {
                    if isPlaying { player.pause() } else { player.play() }
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill").imageScale(.large)
                }
                Button { seek(by: 30) } label: {
                    Image(systemName: "goforward.30").imageScale(.large)
                }
                Spacer()
                if let onDismiss = onDismiss {
                    Button("Dismiss", action: onDismiss)
                        .buttonStyle(.bordered)
                }
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 8)
    }

    private func seek(by seconds: Double) {
        let newTime = max(0, min((currentTime + seconds), duration))
        currentTime = newTime
        let time = CMTime(seconds: newTime, preferredTimescale: 600)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "--:--" }
        let intSec = Int(seconds)
        let m = intSec / 60
        let s = intSec % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func observeDuration(item: AVPlayerItem) {
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { _ in
            isPlaying = false
            currentTime = duration
        }
        // KVO for duration
        item.observe(\AVPlayerItem.duration, options: [.new]) { _, _ in
            let dur = item.duration
            if dur.isNumeric { duration = CMTimeGetSeconds(dur) }
        }
    }

    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            currentTime = CMTimeGetSeconds(time)
        }
    }

    private func removePeriodicTimeObserver() {
        if let token = timeObserverToken { player.removeTimeObserver(token); timeObserverToken = nil }
    }
}

#Preview {
    // Sample local URL preview (won't play without a valid URL)
    TrailerPlayerView(url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!)
}

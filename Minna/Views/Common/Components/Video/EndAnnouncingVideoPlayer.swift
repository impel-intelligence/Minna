//
//  EndAnnouncingVideoPlayer.swift
//  Minna
//
//  Created by Taylor Lineman on 8/11/26.
//

import AppKit
import SwiftUI
import AVKit

struct EndAnnouncingVideoPlayer: NSViewRepresentable {
    var url: URL
    let done: () -> Void
    let doneLoading: () -> Void

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()

        context.coordinator.setPlayer(with: url, on: view)
        
        view.allowsPictureInPicturePlayback = false
        view.controlsStyle = .none
        view.videoGravity = .resizeAspectFill
            
        return view
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        context.coordinator.updatePlayerIfNeeded(with: url, on: nsView)
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(done: done, doneLoading: doneLoading)
    }
    
    class Coordinator: NSObject {
        let done: () -> Void
        let doneLoading: () -> Void
        
        private var player: AVPlayer?
        private var currentURL: URL?
        private var loadObserver: NSKeyValueObservation?

        init(done: @escaping () -> Void, doneLoading: @escaping () -> Void) {
            self.done = done
            self.doneLoading = doneLoading
        }

        func setPlayer(with url: URL, on view: AVPlayerView) {
            currentURL = url
            player = AVPlayer(url: url)
            player?.actionAtItemEnd = .pause
            view.player = player

            let currentItem = player?.currentItem
            if currentItem?.currentTime() == currentItem?.duration {
                currentItem?.seek(to: .zero, completionHandler: nil)
            }

            player?.play()

            NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)

            // Place an observer on the current item status and wait for to become ready to play. Once it is tell the view.
            loadObserver = player?.observe(\.currentItem?.status, changeHandler: { player, _ in
                if player.currentItem?.status == .readyToPlay {
                    Task { @MainActor in
                        self.doneLoading()
                    }
                }
            })

        }

        func updatePlayerIfNeeded(with url: URL, on view: AVPlayerView) {
            guard url != currentURL else { return }
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
            setPlayer(with: url, on: view)
        }

        @objc func videoDidEnd() {
            done()
        }
    }
}

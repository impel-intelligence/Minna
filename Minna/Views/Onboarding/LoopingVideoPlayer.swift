//
//  CustomVideoPlayer.swift
//  Minna
//
//  Created by Taylor Lineman on 8/10/26.
//

import AppKit
import SwiftUI
import AVKit

struct LoopingVideoPlayer: NSViewRepresentable {
    var url: URL
    
    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        
        context.coordinator.setPlayer(with: url, on: view)

        view.allowsPictureInPicturePlayback = false
        view.controlsStyle = .none
        view.videoGravity = .resizeAspectFill
            
        return view
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        context.coordinator.setPlayer(with: url, on: nsView)
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    class Coordinator: NSObject {
        private var observer: NSKeyValueObservation?
        
        var queuePlayer: AVQueuePlayer = AVQueuePlayer()
        var looper: AVPlayerLooper?

        func setPlayer(with url: URL, on view: AVPlayerView) {
            let playerItem = AVPlayerItem(url: url)
            looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)

            view.player = queuePlayer

            queuePlayer.play()
        }
        
        deinit {
            observer?.invalidate()
        }
    }
}

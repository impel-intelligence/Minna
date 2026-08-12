//
//  PlayerView.swift
//  Minna
//
//  Created by Taylor Lineman on 8/11/26.
//

import Foundation
import AppKit
import AVKit

@MainActor
final class PlayerView: NSView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var loadObserver: NSKeyValueObservation?
    private var doneLoading: (() -> Void)?
    private var done: (() -> Void)?
    private var failedToLoad: (() -> Void)?
    
    private var looping: Bool
    private var currentURL: URL?
    
    init(url: URL, looping: Bool, doneLoading: (() -> Void)?, done: (() -> Void)?, failedToLoad: (() -> Void)?) {
        self.doneLoading = doneLoading
        self.done = done
        self.failedToLoad = failedToLoad
        self.looping = looping
        
        super.init(frame: .zero)
        wantsLayer = true
        setupPlayer(url: url)
    }

    required init?(coder: NSCoder) {
        looping = false
        
        super.init(coder: coder)
        wantsLayer = true
    }
    
    public func reSetupPlayer(url: URL) {
        guard currentURL != url else { return }
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        setupPlayer(url: url)
    }

    private func setupPlayer(url: URL) {
        currentURL = url
        
        player = AVPlayer(url: url)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        layer = playerLayer
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        
        loadObserver = player?.observe(\.currentItem?.status, changeHandler: { [weak self] player, _ in
            if player.currentItem?.status == .readyToPlay {
                Task { @MainActor in
                    self?.doneLoading?()
                }
            } else if player.currentItem?.status == .failed {
                Task { @MainActor in
                    self?.failedToLoad?()
                }
            }
        })
        
        player?.play()
    }

    @objc private func playerDidFinishPlaying(note: NSNotification) {
        Task { @MainActor in
            self.done?()
        }
        
        if looping {
            player?.seek(to: .zero)
            player?.play()
        }
    }

    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }

    deinit {
        loadObserver?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

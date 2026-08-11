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

    func makeNSView(context: Context) -> PlayerView {
        return PlayerView(url: url, looping: false, doneLoading: doneLoading, done: done)
    }
    
    func updateNSView(_ nsView: PlayerView, context: Context) {
        nsView.reSetupPlayer(url: url)
    }
}

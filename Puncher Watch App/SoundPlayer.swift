//
//  SoundPlayer.swift
//  Puncher Watch App
//
//  Created by Codex on 2026/5/27.
//

import AVFAudio
import Foundation

@MainActor
final class SoundPlayer {
    private var player: AVAudioPlayer?
    private(set) var errorMessage: String?

    init(bundle: Bundle = .main) {
        let soundURL = bundle.url(forResource: "swing", withExtension: "wav", subdirectory: "Resources")
            ?? bundle.url(forResource: "swing", withExtension: "wav")

        guard let soundURL else {
            errorMessage = "找不到挥动音效。"
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: soundURL)
            player?.prepareToPlay()
        } catch {
            errorMessage = "音效无法载入。"
        }
    }

    @discardableResult
    func play() -> Bool {
        guard let player else {
            return false
        }

        player.currentTime = 0
        let didPlay = player.play()
        if !didPlay {
            errorMessage = "音效播放失败。"
        }
        return didPlay
    }
}

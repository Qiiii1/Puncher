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
    private var players: [MotionTriggerEffect: AVAudioPlayer] = [:]
    private(set) var errorMessage: String?

    init(bundle: Bundle = .main) {
        MotionTriggerEffect.allCases.forEach { effect in
            load(effect, from: bundle)
        }
    }

    @discardableResult
    func play(_ effect: MotionTriggerEffect = .basic) -> Bool {
        guard let player = players[effect] else {
            appendError("找不到\(effect.title)音效。")
            return false
        }

        player.currentTime = 0
        let didPlay = player.play()
        if !didPlay {
            errorMessage = "\(effect.title)音效播放失败。"
        }
        return didPlay
    }

    private func load(_ effect: MotionTriggerEffect, from bundle: Bundle) {
        let soundURL = bundle.url(
            forResource: effect.resourceName,
            withExtension: "mp3",
            subdirectory: "AudioResource"
        ) ?? bundle.url(forResource: effect.resourceName, withExtension: "mp3")

        guard let soundURL else {
            appendError("找不到\(effect.title)音效。")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.prepareToPlay()
            players[effect] = player
        } catch {
            appendError("\(effect.title)音效无法载入。")
        }
    }

    private func appendError(_ message: String) {
        if let errorMessage {
            self.errorMessage = "\(errorMessage)\n\(message)"
        } else {
            errorMessage = message
        }
    }
}

private extension MotionTriggerEffect {
    var resourceName: String {
        switch self {
        case .basic:
            "基础音效"
        case .enhanced:
            "强化音效"
        }
    }

    var title: String {
        switch self {
        case .basic:
            "基础"
        case .enhanced:
            "强化"
        }
    }
}

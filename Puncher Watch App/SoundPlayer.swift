//
//  SoundPlayer.swift
//  Puncher Watch App
//
//  Created by Codex on 2026/5/27.
//

import AVFAudio
import Foundation

@MainActor
final class SoundPlayer: NSObject, AVAudioPlayerDelegate {
    private var players: [MotionTriggerEffect: AVAudioPlayer] = [:]
    private var playbackLimiter = SoundPlaybackLimiter()
    private let playbackRate: Float = 1.15
    private(set) var errorMessage: String?

    init(bundle: Bundle = .main) {
        super.init()
        configureAudioSession()
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

        guard let effectToStart = playbackLimiter.request(effect) else {
            return true
        }

        return start(effectToStart, with: player)
    }

    private func start(_ effect: MotionTriggerEffect, with player: AVAudioPlayer? = nil) -> Bool {
        guard let player = player ?? players[effect] else {
            appendError("找不到\(effect.title)音效。")
            playbackLimiter.cancelAll()
            return false
        }

        player.currentTime = 0
        player.rate = playbackRate
        let didPlay = player.play()
        if !didPlay {
            errorMessage = "\(effect.title)音效播放失败。"
            playbackLimiter.cancelAll()
        }
        return didPlay
    }

    private func beginRestAfterPlayback() {
        guard let restInterval = playbackLimiter.finishCurrent() else {
            return
        }

        Task { @MainActor [weak self] in
            let nanoseconds = UInt64(restInterval * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            self?.playbackLimiter.finishRest()
        }
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
            player.delegate = self
            player.enableRate = true
            player.rate = playbackRate
            player.prepareToPlay()
            players[effect] = player
        } catch {
            appendError("\(effect.title)音效无法载入。")
        }
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        #if !os(watchOS)
        try? session.setPreferredIOBufferDuration(0.005)
        #endif
        try? session.setActive(true)
    }

    private func appendError(_ message: String) {
        if let errorMessage {
            self.errorMessage = "\(errorMessage)\n\(message)"
        } else {
            errorMessage = message
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            self?.beginRestAfterPlayback()
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self] in
            if let error {
                self?.appendError("音效播放中断：\(error.localizedDescription)")
            } else {
                self?.appendError("音效播放中断。")
            }
            self?.beginRestAfterPlayback()
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

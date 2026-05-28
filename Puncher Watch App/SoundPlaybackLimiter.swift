//
//  SoundPlaybackLimiter.swift
//  Puncher Watch App
//
//  Created by Codex on 2026/5/28.
//

import Foundation

nonisolated struct SoundPlaybackLimiter {
    static let defaultRestInterval: TimeInterval = 0.35

    let restInterval: TimeInterval
    private(set) var currentEffect: MotionTriggerEffect?
    private(set) var isResting = false

    var isPlaying: Bool {
        currentEffect != nil
    }

    init(restInterval: TimeInterval = Self.defaultRestInterval) {
        self.restInterval = restInterval
    }

    mutating func request(_ effect: MotionTriggerEffect) -> MotionTriggerEffect? {
        guard currentEffect == nil, !isResting else {
            return nil
        }

        currentEffect = effect
        return effect
    }

    mutating func finishCurrent() -> TimeInterval? {
        guard currentEffect != nil else {
            return nil
        }

        currentEffect = nil
        isResting = true
        return restInterval
    }

    mutating func finishRest() {
        isResting = false
    }

    mutating func cancelAll() {
        currentEffect = nil
        isResting = false
    }
}

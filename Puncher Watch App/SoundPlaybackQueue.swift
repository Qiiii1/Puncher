//
//  SoundPlaybackQueue.swift
//  Puncher Watch App
//
//  Created by Codex on 2026/5/28.
//

nonisolated struct SoundPlaybackQueue {
    private(set) var currentEffect: MotionTriggerEffect?
    private var pendingEffects: [MotionTriggerEffect] = []

    var queuedEffectCount: Int {
        pendingEffects.count
    }

    mutating func request(_ effect: MotionTriggerEffect) -> MotionTriggerEffect? {
        guard currentEffect == nil else {
            pendingEffects.append(effect)
            return nil
        }

        currentEffect = effect
        return effect
    }

    mutating func finishCurrent() -> MotionTriggerEffect? {
        guard currentEffect != nil else {
            return nil
        }

        guard !pendingEffects.isEmpty else {
            currentEffect = nil
            return nil
        }

        let nextEffect = pendingEffects.removeFirst()
        currentEffect = nextEffect
        return nextEffect
    }

    mutating func cancelAll() {
        currentEffect = nil
        pendingEffects.removeAll()
    }
}

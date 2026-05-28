//
//  MotionTriggerDetector.swift
//  Puncher Watch App
//
//  Created by Codex on 2026/5/27.
//

import Foundation

struct MotionSample {
    let accelerationMagnitude: Double
    let rotationMagnitude: Double
    let timestamp: TimeInterval

    init(accelerationMagnitude: Double, rotationMagnitude: Double, timestamp: TimeInterval) {
        self.accelerationMagnitude = accelerationMagnitude
        self.rotationMagnitude = rotationMagnitude
        self.timestamp = timestamp
    }

    init(
        accelerationX: Double,
        accelerationY: Double,
        accelerationZ: Double,
        rotationX: Double,
        rotationY: Double,
        rotationZ: Double,
        timestamp: TimeInterval
    ) {
        accelerationMagnitude = sqrt(
            accelerationX * accelerationX
                + accelerationY * accelerationY
                + accelerationZ * accelerationZ
        )
        rotationMagnitude = sqrt(
            rotationX * rotationX
                + rotationY * rotationY
                + rotationZ * rotationZ
        )
        self.timestamp = timestamp
    }
}

nonisolated enum MotionTriggerEffect: CaseIterable, Equatable, Hashable {
    case basic
    case enhanced
}

struct MotionTriggerDetector {
    var sensitivity: Double
    var cooldown: TimeInterval
    var comboWindow: TimeInterval

    private var lastTriggerTime: TimeInterval?
    private var consecutiveTriggerCount = 0

    init(sensitivity: Double, cooldown: TimeInterval = 0.35, comboWindow: TimeInterval = 1.5) {
        self.sensitivity = sensitivity
        self.cooldown = cooldown
        self.comboWindow = comboWindow
    }

    private var thresholdScale: Double {
        1.25 - min(max(sensitivity, 0.0), 1.0) * 0.5
    }

    private var accelerationThreshold: Double {
        1.05 * thresholdScale
    }

    private var rotationThreshold: Double {
        2.4 * thresholdScale
    }

    mutating func trigger(for sample: MotionSample) -> MotionTriggerEffect? {
        guard sample.accelerationMagnitude >= accelerationThreshold,
              sample.rotationMagnitude >= rotationThreshold else {
            return nil
        }

        if let lastTriggerTime,
           sample.timestamp - lastTriggerTime < cooldown {
            return nil
        }

        if let lastTriggerTime,
           sample.timestamp - lastTriggerTime <= comboWindow {
            consecutiveTriggerCount += 1
        } else {
            consecutiveTriggerCount = 1
        }

        lastTriggerTime = sample.timestamp
        if consecutiveTriggerCount >= 3 {
            consecutiveTriggerCount = 0
            return .enhanced
        }

        return .basic
    }

    mutating func shouldTrigger(for sample: MotionSample) -> Bool {
        trigger(for: sample) != nil
    }

    func intensity(for sample: MotionSample) -> Double {
        let accelerationRatio = sample.accelerationMagnitude / accelerationThreshold
        let rotationRatio = sample.rotationMagnitude / rotationThreshold
        return min(max(accelerationRatio, rotationRatio) / 1.5, 1.0)
    }
}

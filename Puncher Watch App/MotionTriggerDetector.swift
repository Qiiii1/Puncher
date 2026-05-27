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
}

struct MotionTriggerDetector {
    var sensitivity: Double
    var cooldown: TimeInterval

    private var lastTriggerTime: TimeInterval?

    init(sensitivity: Double, cooldown: TimeInterval = 0.35) {
        self.sensitivity = sensitivity
        self.cooldown = cooldown
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

    mutating func shouldTrigger(for sample: MotionSample) -> Bool {
        guard sample.accelerationMagnitude >= accelerationThreshold,
              sample.rotationMagnitude >= rotationThreshold else {
            return false
        }

        if let lastTriggerTime,
           sample.timestamp - lastTriggerTime < cooldown {
            return false
        }

        lastTriggerTime = sample.timestamp
        return true
    }

    func intensity(for sample: MotionSample) -> Double {
        let accelerationRatio = sample.accelerationMagnitude / accelerationThreshold
        let rotationRatio = sample.rotationMagnitude / rotationThreshold
        return min(max(accelerationRatio, rotationRatio) / 1.5, 1.0)
    }
}

//
//  Puncher_Watch_AppTests.swift
//  Puncher Watch AppTests
//
//  Created by 李棋 on 2026/5/27.
//

import Testing
@testable import Puncher_Watch_App

struct MotionTriggerDetectorTests {

    @Test func deliberateFastSwingTriggers() {
        var detector = MotionTriggerDetector(sensitivity: 0.5)

        let triggered = detector.shouldTrigger(
            for: MotionSample(
                accelerationMagnitude: 1.1,
                rotationMagnitude: 2.5,
                timestamp: 1.0
            )
        )

        #expect(triggered)
    }

    @Test func minorMovementIsIgnored() {
        var detector = MotionTriggerDetector(sensitivity: 0.5)

        let triggered = detector.shouldTrigger(
            for: MotionSample(
                accelerationMagnitude: 0.2,
                rotationMagnitude: 0.4,
                timestamp: 1.0
            )
        )

        #expect(!triggered)
    }

    @Test func cooldownSuppressesRepeatTriggers() {
        var detector = MotionTriggerDetector(sensitivity: 0.5)
        let first = MotionSample(
            accelerationMagnitude: 1.2,
            rotationMagnitude: 3.0,
            timestamp: 1.0
        )
        let repeated = MotionSample(
            accelerationMagnitude: 1.2,
            rotationMagnitude: 3.0,
            timestamp: 1.2
        )
        let later = MotionSample(
            accelerationMagnitude: 1.2,
            rotationMagnitude: 3.0,
            timestamp: 1.36
        )
        let acceptedFirst = detector.shouldTrigger(for: first)
        let rejectedRepeat = detector.shouldTrigger(for: repeated)
        let acceptedLater = detector.shouldTrigger(for: later)

        #expect(acceptedFirst)
        #expect(!rejectedRepeat)
        #expect(acceptedLater)
    }

    @Test func higherSensitivityAcceptsAWeakerSwing() {
        let weakerSwing = MotionSample(
            accelerationMagnitude: 0.9,
            rotationMagnitude: 2.0,
            timestamp: 1.0
        )
        var lowSensitivity = MotionTriggerDetector(sensitivity: 0.0)
        var highSensitivity = MotionTriggerDetector(sensitivity: 1.0)
        let lowTriggered = lowSensitivity.shouldTrigger(for: weakerSwing)
        let highTriggered = highSensitivity.shouldTrigger(for: weakerSwing)

        #expect(!lowTriggered)
        #expect(highTriggered)
    }

    @Test func vectorComponentsProduceMagnitudes() {
        let sample = MotionSample(
            accelerationX: 3.0,
            accelerationY: 4.0,
            accelerationZ: 0.0,
            rotationX: 0.0,
            rotationY: 0.0,
            rotationZ: 2.0,
            timestamp: 1.0
        )

        #expect(sample.accelerationMagnitude == 5.0)
        #expect(sample.rotationMagnitude == 2.0)
    }
}

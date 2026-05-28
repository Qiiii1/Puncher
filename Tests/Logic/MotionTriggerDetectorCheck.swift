import Darwin
import Foundation

@main
struct MotionTriggerDetectorCheck {

    static func main() {
        deliberateFastSwingTriggers()
        minorMovementIsIgnored()
        cooldownSuppressesRepeatTriggers()
        thirdConsecutiveTriggerUsesEnhancedEffect()
        comboWindowResetStartsBackAtBasic()
        higherSensitivityAcceptsAWeakerSwing()
        sensitivityUsesZeroToOneHundredScale()
        defaultCooldownAllowsFastFollowUpSwing()
        vectorComponentsProduceMagnitudes()
        print("MotionTriggerDetector checks passed")
    }

    private static func deliberateFastSwingTriggers() {
        var detector = MotionTriggerDetector(sensitivity: 50.0)
        require(
            detector.shouldTrigger(
                for: MotionSample(
                    accelerationMagnitude: 1.1,
                    rotationMagnitude: 2.5,
                    timestamp: 1.0
                )
            ),
            "a deliberate fast swing should trigger"
        )
    }

    private static func minorMovementIsIgnored() {
        var detector = MotionTriggerDetector(sensitivity: 50.0)
        require(
            !detector.shouldTrigger(
                for: MotionSample(
                    accelerationMagnitude: 0.2,
                    rotationMagnitude: 0.4,
                    timestamp: 1.0
                )
            ),
            "minor movement should not trigger"
        )
    }

    private static func cooldownSuppressesRepeatTriggers() {
        var detector = MotionTriggerDetector(sensitivity: 50.0)
        let sample = MotionSample(
            accelerationMagnitude: 1.2,
            rotationMagnitude: 3.0,
            timestamp: 1.0
        )

        require(detector.shouldTrigger(for: sample), "first fast sample should trigger")
        require(
            !detector.shouldTrigger(
                for: MotionSample(
                    accelerationMagnitude: 1.2,
                    rotationMagnitude: 3.0,
                    timestamp: 1.1
                )
            ),
            "a repeat during cooldown should not trigger"
        )
        require(
            detector.shouldTrigger(
                for: MotionSample(
                    accelerationMagnitude: 1.2,
                    rotationMagnitude: 3.0,
                    timestamp: 1.22
                )
            ),
            "a later swing should trigger"
        )
    }

    private static func thirdConsecutiveTriggerUsesEnhancedEffect() {
        var detector = MotionTriggerDetector(sensitivity: 50.0)

        require(detector.trigger(for: strongSwing(at: 1.0)) == .basic, "first swing should use basic sound")
        require(detector.trigger(for: strongSwing(at: 1.4)) == .basic, "second swing should use basic sound")
        require(detector.trigger(for: strongSwing(at: 1.8)) == .enhanced, "third swing should use enhanced sound")
    }

    private static func comboWindowResetStartsBackAtBasic() {
        var detector = MotionTriggerDetector(sensitivity: 50.0)

        require(detector.trigger(for: strongSwing(at: 1.0)) == .basic, "first swing should use basic sound")
        require(detector.trigger(for: strongSwing(at: 1.4)) == .basic, "second swing should use basic sound")
        require(detector.trigger(for: strongSwing(at: 3.1)) == .basic, "delayed swing should restart combo")
    }

    private static func higherSensitivityAcceptsAWeakerSwing() {
        let sample = MotionSample(
            accelerationMagnitude: 0.9,
            rotationMagnitude: 2.0,
            timestamp: 1.0
        )
        var lowSensitivity = MotionTriggerDetector(sensitivity: 0.0)
        var highSensitivity = MotionTriggerDetector(sensitivity: 100.0)

        require(
            !lowSensitivity.shouldTrigger(for: sample),
            "low sensitivity should reject a weaker swing"
        )
        require(
            highSensitivity.shouldTrigger(for: sample),
            "high sensitivity should accept a weaker swing"
        )
    }

    private static func sensitivityUsesZeroToOneHundredScale() {
        let sample = MotionSample(
            accelerationMagnitude: 0.9,
            rotationMagnitude: 2.0,
            timestamp: 1.0
        )
        var midpointSensitivity = MotionTriggerDetector(sensitivity: 50.0)
        var maximumSensitivity = MotionTriggerDetector(sensitivity: 100.0)

        require(
            !midpointSensitivity.shouldTrigger(for: sample),
            "50 sensitivity should remain the midpoint, not the maximum"
        )
        require(
            maximumSensitivity.shouldTrigger(for: sample),
            "100 sensitivity should be the maximum"
        )
    }

    private static func defaultCooldownAllowsFastFollowUpSwing() {
        var detector = MotionTriggerDetector(sensitivity: 100.0)

        require(detector.trigger(for: strongSwing(at: 1.0)) == .basic, "first swing should trigger")
        require(
            detector.trigger(for: strongSwing(at: 1.22)) == .basic,
            "fast follow-up swing should not feel delayed by the default cooldown"
        )
    }

    private static func vectorComponentsProduceMagnitudes() {
        let sample = MotionSample(
            accelerationX: 3.0,
            accelerationY: 4.0,
            accelerationZ: 0.0,
            rotationX: 0.0,
            rotationY: 0.0,
            rotationZ: 2.0,
            timestamp: 1.0
        )

        require(sample.accelerationMagnitude == 5.0, "acceleration magnitude should be calculated")
        require(sample.rotationMagnitude == 2.0, "rotation magnitude should be calculated")
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            exit(EXIT_FAILURE)
        }
    }

    private static func strongSwing(at timestamp: TimeInterval) -> MotionSample {
        MotionSample(
            accelerationMagnitude: 1.2,
            rotationMagnitude: 3.0,
            timestamp: timestamp
        )
    }
}

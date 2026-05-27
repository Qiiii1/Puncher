import Darwin
import Foundation

@main
struct MotionTriggerDetectorCheck {

    static func main() {
        deliberateFastSwingTriggers()
        minorMovementIsIgnored()
        cooldownSuppressesRepeatTriggers()
        higherSensitivityAcceptsAWeakerSwing()
        vectorComponentsProduceMagnitudes()
        print("MotionTriggerDetector checks passed")
    }

    private static func deliberateFastSwingTriggers() {
        var detector = MotionTriggerDetector(sensitivity: 0.5)
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
        var detector = MotionTriggerDetector(sensitivity: 0.5)
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
        var detector = MotionTriggerDetector(sensitivity: 0.5)
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
                    timestamp: 1.2
                )
            ),
            "a repeat during cooldown should not trigger"
        )
        require(
            detector.shouldTrigger(
                for: MotionSample(
                    accelerationMagnitude: 1.2,
                    rotationMagnitude: 3.0,
                    timestamp: 1.36
                )
            ),
            "a later swing should trigger"
        )
    }

    private static func higherSensitivityAcceptsAWeakerSwing() {
        let sample = MotionSample(
            accelerationMagnitude: 0.9,
            rotationMagnitude: 2.0,
            timestamp: 1.0
        )
        var lowSensitivity = MotionTriggerDetector(sensitivity: 0.0)
        var highSensitivity = MotionTriggerDetector(sensitivity: 1.0)

        require(
            !lowSensitivity.shouldTrigger(for: sample),
            "low sensitivity should reject a weaker swing"
        )
        require(
            highSensitivity.shouldTrigger(for: sample),
            "high sensitivity should accept a weaker swing"
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
}

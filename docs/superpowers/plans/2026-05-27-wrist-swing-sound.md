# Wrist Swing Sound Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a SwiftUI watchOS prototype that detects a fast wrist swing while visible and plays a locally generated sound.

**Architecture:** Keep the trigger rule in a pure Swift `MotionTriggerDetector`, so its thresholds and cooldown can run without Apple Watch hardware. `MotionMonitor` adapts `CMDeviceMotion` samples into that detector and publishes UI state, while `SoundPlayer` owns one short generated WAV resource. `ContentView` is the SwiftUI tuning and status surface.

**Tech Stack:** SwiftUI, Core Motion, AVFAudio, Swift Testing, Xcode watchOS 26.2 project, Git/GitHub CLI

**Validation constraint:** This Mac has watchOS 26.2 SDKs but no installed watchOS simulator runtime; detector behavior can be executed locally, while full watch target build/test must be retried once the watchOS platform component is installed in Xcode.

---

### Task 1: Isolated Feature Workspace

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Confirm `.worktrees/` is ignored**

Run: `git check-ignore -q '.worktrees/probe'`
Expected: exit `0`, because local feature worktrees are not project content.

- [ ] **Step 2: Create the feature workspace**

Run: `git worktree add '.worktrees/wrist-swing-sound' -b 'codex/wrist-swing-sound'`
Expected: a linked checkout based on `main`.

### Task 2: Motion Trigger Rule

**Files:**
- Create: `Puncher Watch App/MotionTriggerDetector.swift`
- Modify: `Puncher Watch AppTests/Puncher_Watch_AppTests.swift`
- Create: `Tests/Logic/MotionTriggerDetectorCheck.swift`

- [ ] **Step 1: Write failing behavioral checks**

Add tests for intentional motion, minor motion, cooldown suppression, and sensitivity:

```swift
var detector = MotionTriggerDetector(sensitivity: 0.5)
#expect(detector.shouldTrigger(for: MotionSample(accelerationMagnitude: 1.1, rotationMagnitude: 2.5, timestamp: 1)))
#expect(!detector.shouldTrigger(for: MotionSample(accelerationMagnitude: 0.2, rotationMagnitude: 0.4, timestamp: 2)))
```

Use the same scenarios in a standalone `@main` assertion checker so they run on macOS without a watchOS runtime.

- [ ] **Step 2: Confirm the checker fails before production code exists**

Run: `swiftc 'Tests/Logic/MotionTriggerDetectorCheck.swift' -o /private/tmp/motion-detector-check`
Expected: FAIL because `MotionTriggerDetector` and `MotionSample` are not defined.

- [ ] **Step 3: Implement the pure detector**

```swift
struct MotionSample {
    let accelerationMagnitude: Double
    let rotationMagnitude: Double
    let timestamp: TimeInterval
}

struct MotionTriggerDetector {
    var sensitivity: Double
    var cooldown: TimeInterval = 0.35
    private var lastTriggerTime: TimeInterval?
    private var thresholdScale: Double { 1.25 - min(max(sensitivity, 0), 1) * 0.5 }
    private var accelerationThreshold: Double { 1.05 * thresholdScale }
    private var rotationThreshold: Double { 2.4 * thresholdScale }

    mutating func shouldTrigger(for sample: MotionSample) -> Bool {
        guard sample.accelerationMagnitude >= accelerationThreshold,
              sample.rotationMagnitude >= rotationThreshold,
              lastTriggerTime.map({ sample.timestamp - $0 >= cooldown }) ?? true else { return false }
        lastTriggerTime = sample.timestamp
        return true
    }

    func intensity(for sample: MotionSample) -> Double {
        min(max(sample.accelerationMagnitude / accelerationThreshold,
                sample.rotationMagnitude / rotationThreshold) / 1.5, 1)
    }
}
```

Thresholds scale downward as sensitivity increases, with default thresholds of `1.05 g` and `2.4 rad/s`.

- [ ] **Step 4: Run portable checks**

Run: `swiftc 'Puncher Watch App/MotionTriggerDetector.swift' 'Tests/Logic/MotionTriggerDetectorCheck.swift' -o /private/tmp/motion-detector-check && /private/tmp/motion-detector-check`
Expected: output `MotionTriggerDetector checks passed`.

### Task 3: Generated Sound And Playback

**Files:**
- Create: `Tools/generate_swing_sound.swift`
- Create (generated): `Puncher Watch App/Resources/swing.wav`
- Create: `Puncher Watch App/SoundPlayer.swift`

- [ ] **Step 1: Generate an original short sound**

Write a Swift generator that writes a mono PCM WAV containing a descending, fading noise/tone burst. Run:

`swift 'Tools/generate_swing_sound.swift' 'Puncher Watch App/Resources/swing.wav'`

Expected: a local WAV resource of approximately `0.18` seconds exists.

- [ ] **Step 2: Add playback service**

```swift
import AVFAudio
import Foundation

@MainActor
final class SoundPlayer {
    private var player: AVAudioPlayer?
    private(set) var errorMessage: String?

    init(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "swing", withExtension: "wav") else {
            errorMessage = "Sound resource is unavailable."
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
        } catch {
            errorMessage = "Sound could not be loaded."
        }
    }

    @discardableResult
    func play() -> Bool {
        guard let player else { return false }
        player.currentTime = 0
        return player.play()
    }
}
```

The service exposes an error string rather than stopping motion monitoring if the sound is unavailable.

### Task 4: Motion Observation And SwiftUI Surface

**Files:**
- Create: `Puncher Watch App/MotionMonitor.swift`
- Modify: `Puncher Watch App/ContentView.swift`
- Modify: `Puncher.xcodeproj/project.pbxproj`

- [ ] **Step 1: Create the observable monitor**

```swift
import Combine
import CoreMotion

@MainActor
final class MotionMonitor: ObservableObject {
    @Published var sensitivity = 0.5
    @Published private(set) var triggerCount = 0
    @Published private(set) var latestIntensity = 0.0
    private let motionManager = CMMotionManager()
    private let soundPlayer = SoundPlayer()
    private var detector = MotionTriggerDetector(sensitivity: 0.5)

    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.process(motion)
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }

    func playTestSound() {
        soundPlayer.play()
    }

    private func process(_ motion: CMDeviceMotion) {
        detector.sensitivity = sensitivity
        let acceleration = motion.userAcceleration
        let rotation = motion.rotationRate
        let sample = MotionSample(
            accelerationMagnitude: sqrt(acceleration.x * acceleration.x + acceleration.y * acceleration.y + acceleration.z * acceleration.z),
            rotationMagnitude: sqrt(rotation.x * rotation.x + rotation.y * rotation.y + rotation.z * rotation.z),
            timestamp: motion.timestamp
        )
        latestIntensity = detector.intensity(for: sample)
        if detector.shouldTrigger(for: sample) {
            triggerCount += 1
            soundPlayer.play()
        }
    }
}
```

Compute vector magnitudes from `userAcceleration` and `rotationRate`, and ask the detector for each accepted trigger.

- [ ] **Step 2: Replace the template with a SwiftUI control surface**

Build a `ScrollView`/`VStack` screen with monitoring status, a `Gauge`, count, `Slider`, audio test button, and any motion/audio unavailability explanation. Call `start()` and `stop()` from view lifecycle callbacks.

- [ ] **Step 3: Declare motion use**

Set `INFOPLIST_KEY_NSMotionUsageDescription` on the watch target configurations to explain that wrist motion is read only while the app is open.

### Task 5: Documentation And Verification

**Files:**
- Create: `README.md`

- [ ] **Step 1: Document use and tuning**

Explain that Puncher is a SwiftUI watchOS prototype; motion is based on acceleration/rotation rather than physical distance; build/run requires an Apple Watch or installed watchOS simulator platform.

- [ ] **Step 2: Re-run detector checks**

Run: `swiftc 'Puncher Watch App/MotionTriggerDetector.swift' 'Tests/Logic/MotionTriggerDetectorCheck.swift' -o /private/tmp/motion-detector-check && /private/tmp/motion-detector-check`
Expected: PASS.

- [ ] **Step 3: Attempt target build and capture platform status**

Run: `xcodebuild -project 'Puncher.xcodeproj' -scheme 'Puncher Watch App' -configuration Debug -sdk watchsimulator -destination 'generic/platform=watchOS Simulator' -derivedDataPath /private/tmp/PuncherDerivedData CODE_SIGNING_ALLOWED=NO build`
Expected after installing the watchOS platform: `BUILD SUCCEEDED`; currently record any missing-platform blocker accurately.

- [ ] **Step 4: Publish**

Commit implementation, create public repository `Qiiii1/Puncher`, merge the verified feature branch to `main`, and push `main` to GitHub.

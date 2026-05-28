# Wrist Swing Sound Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a SwiftUI watchOS prototype that detects fast wrist swings while visible, plays a basic sound for normal triggers, plays an enhanced sound on every third consecutive trigger, and queues effects so one sound finishes before the next begins.

**Architecture:** Keep the trigger rule in a pure Swift `MotionTriggerDetector`, so its thresholds, cooldown, and combo counter can run without Apple Watch hardware. `MotionMonitor` adapts `CMDeviceMotion` samples into that detector and publishes UI state, while `SoundPlayer` owns the bundled basic and enhanced MP3 resources and `SoundPlaybackQueue` serializes playback. `ContentView` is the SwiftUI tuning and status surface.

**Tech Stack:** SwiftUI, Core Motion, AVFAudio, Swift Testing, Xcode watchOS 26.2 project, Git/GitHub CLI

**Validation constraint:** This Mac has watchOS 26.2 SDKs but no installed watchOS simulator runtime. The Watch App and test targets can be built against the SDK, and detector behavior can run locally; executing tests or tuning a gesture needs a watchOS runtime or physical Apple Watch.

---

### Task 1: Isolated Feature Workspace

**Files:**
- Modify: `.gitignore`

- [x] **Step 1: Confirm `.worktrees/` is ignored**

Run: `git check-ignore -q '.worktrees/probe'`
Expected: exit `0`, because local feature worktrees are not project content.

- [x] **Step 2: Create the feature workspace**

Run: `git worktree add '.worktrees/wrist-swing-sound' -b 'codex/wrist-swing-sound'`
Expected: a linked checkout based on `main`.

### Task 2: Motion Trigger Rule

**Files:**
- Create: `Puncher Watch App/MotionTriggerDetector.swift`
- Modify: `Puncher Watch AppTests/Puncher_Watch_AppTests.swift`
- Create: `Tests/Logic/MotionTriggerDetectorCheck.swift`

- [x] **Step 1: Write failing behavioral checks**

Add tests for intentional motion, minor motion, cooldown suppression, and sensitivity:

```swift
var detector = MotionTriggerDetector(sensitivity: 50.0)
#expect(detector.shouldTrigger(for: MotionSample(accelerationMagnitude: 1.1, rotationMagnitude: 2.5, timestamp: 1)))
#expect(!detector.shouldTrigger(for: MotionSample(accelerationMagnitude: 0.2, rotationMagnitude: 0.4, timestamp: 2)))
```

Use the same scenarios in a standalone `@main` assertion checker so they run on macOS without a watchOS runtime.

- [x] **Step 2: Confirm the checker fails before production code exists**

Run: `swiftc -parse-as-library 'Tests/Logic/MotionTriggerDetectorCheck.swift' -o /private/tmp/motion-detector-check`
Expected: FAIL because `MotionTriggerDetector` and `MotionSample` are not defined.

- [x] **Step 3: Implement the pure detector**

```swift
struct MotionSample {
    let accelerationMagnitude: Double
    let rotationMagnitude: Double
    let timestamp: TimeInterval
}

struct MotionTriggerDetector {
    static let defaultSensitivity = 70.0

    var sensitivity: Double
    var cooldown: TimeInterval
    private var lastTriggerTime: TimeInterval?
    init(sensitivity: Double, cooldown: TimeInterval = 0.2) {
        self.sensitivity = sensitivity
        self.cooldown = cooldown
    }
    private var normalizedSensitivity: Double { min(max(sensitivity, 0), 100) / 100 }
    private var thresholdScale: Double { 1.25 - normalizedSensitivity * 0.5 }
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

Thresholds scale downward as sensitivity increases on a `0...100` scale, with midpoint thresholds of `1.05 g` and `2.4 rad/s`. The app starts at `70` instead of the maximum to avoid accidental triggers.

- [x] **Step 4: Run portable checks**

Run: `swiftc -parse-as-library 'Puncher Watch App/MotionTriggerDetector.swift' 'Tests/Logic/MotionTriggerDetectorCheck.swift' -o /private/tmp/motion-detector-check && /private/tmp/motion-detector-check`
Expected: output `MotionTriggerDetector checks passed`.

### Task 3: Audio Resources And Playback

**Files:**
- Add: `Puncher Watch App/AudioResource/基础音效.mp3`
- Add: `Puncher Watch App/AudioResource/强化音效.mp3`
- Create: `Puncher Watch App/SoundPlaybackQueue.swift`
- Create: `Tests/Logic/SoundPlaybackQueueCheck.swift`
- Create: `Puncher Watch App/SoundPlayer.swift`

- [x] **Step 1: Add bundled MP3 resources**

Verify that both MP3 resources exist under `Puncher Watch App/AudioResource` and contain audio data.

- [x] **Step 2: Add playback service**

```swift
import AVFAudio
import Foundation

@MainActor
final class SoundPlayer: NSObject, AVAudioPlayerDelegate {
    private var players: [MotionTriggerEffect: AVAudioPlayer] = [:]
    private var playbackQueue = SoundPlaybackQueue()
    private(set) var errorMessage: String?

    init(bundle: Bundle = .main) {
        MotionTriggerEffect.allCases.forEach { effect in
            load(effect, from: bundle)
        }
    }

    @discardableResult
    func play(_ effect: MotionTriggerEffect) -> Bool {
        guard let player = players[effect] else { return false }
        guard playbackQueue.request(effect) != nil else { return true }
        player.currentTime = 0
        player.rate = 1.15
        return player.play()
    }

    private func load(_ effect: MotionTriggerEffect, from bundle: Bundle) {
        guard let url = bundle.url(
            forResource: effect.resourceName,
            withExtension: "mp3",
            subdirectory: "AudioResource"
        ) else {
            errorMessage = "Sound resource is unavailable."
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.enableRate = true
            player.rate = 1.15
            player.prepareToPlay()
            players[effect] = player
        } catch {
            errorMessage = "Sound could not be loaded."
        }
    }
}
```

The service exposes an error string rather than stopping motion monitoring if the sound is unavailable. Playback is serialized: a new effect waits until the current `AVAudioPlayer` delegate callback reports completion.

### Task 4: Motion Observation And SwiftUI Surface

**Files:**
- Create: `Puncher Watch App/MotionMonitor.swift`
- Modify: `Puncher Watch App/ContentView.swift`
- Modify: `Puncher.xcodeproj/project.pbxproj`

- [x] **Step 1: Create the observable monitor**

```swift
import Combine
import CoreMotion

@MainActor
final class MotionMonitor: ObservableObject {
    @Published var sensitivity = MotionTriggerDetector.defaultSensitivity
    @Published private(set) var triggerCount = 0
    @Published private(set) var latestIntensity = 0.0
    private let motionManager = CMMotionManager()
    private let soundPlayer = SoundPlayer()
    private var detector = MotionTriggerDetector(sensitivity: MotionTriggerDetector.defaultSensitivity)

    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 100.0
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

- [x] **Step 2: Replace the template with a SwiftUI control surface**

Build a `ScrollView`/`VStack` screen with monitoring status, a `Gauge`, count, `Slider`, audio test button, and any motion/audio unavailability explanation. Call `start()` and `stop()` from view lifecycle callbacks.

- [x] **Step 3: Declare motion use**

Set `INFOPLIST_KEY_NSMotionUsageDescription` on the watch target configurations to explain that wrist motion is read only while the app is open.

### Task 5: Documentation And Verification

**Files:**
- Create: `README.md`

- [x] **Step 1: Document use and tuning**

Explain that Puncher is a SwiftUI watchOS prototype; motion is based on acceleration/rotation rather than physical distance; build/run requires an Apple Watch or installed watchOS simulator platform.

- [x] **Step 2: Re-run detector checks**

Run: `swiftc -parse-as-library 'Puncher Watch App/MotionTriggerDetector.swift' 'Tests/Logic/MotionTriggerDetectorCheck.swift' -o /private/tmp/motion-detector-check && /private/tmp/motion-detector-check`
Expected: PASS.

- [x] **Step 3: Build application and test targets**

Run: `xcodebuild -project 'Puncher.xcodeproj' -target 'Puncher Watch App' -configuration Debug -sdk watchsimulator CODE_SIGNING_ALLOWED=NO OBJROOT=/private/tmp/PuncherWatchTargetBuild/Obj SYMROOT=/private/tmp/PuncherWatchTargetBuild/Sym build`

Run: `xcodebuild -project 'Puncher.xcodeproj' -target 'Puncher Watch AppTests' -configuration Debug -sdk watchsimulator CODE_SIGNING_ALLOWED=NO OBJROOT=/private/tmp/PuncherWatchTestsBuild/Obj SYMROOT=/private/tmp/PuncherWatchTestsBuild/Sym build`

Expected: `BUILD SUCCEEDED` for both targets. Executing the test bundle remains a physical-watch or installed-runtime validation.

- [x] **Step 4: Publish**

Commit implementation, create public repository `Qiiii1/Puncher`, merge the verified feature branch to `main`, and push `main` to GitHub.

# Wrist Swing Sound Design

## Goal

Build a watchOS prototype that plays a short sound when the wearer makes a quick wrist-swing motion while the app is visible and active.

## Scope

- Monitor live Apple Watch motion only while the app is in the foreground.
- Detect a deliberate fast swing using motion intensity and rotation, not an estimated physical distance.
- Play the basic sound for normal accepted gestures and the enhanced sound on the third consecutive accepted gesture.
- Do not overlap or interrupt sound effects; queue later effects until the current effect finishes.
- Show monitoring state, latest intensity, trigger count, and a sensitivity control for on-wrist tuning.
- Publish the project in a public GitHub repository named `Puncher`.

The prototype does not monitor in the background, run a workout session, estimate centimeters of travel, classify swing direction, or persist analytics.

## Platform Capability

`CoreMotion.CMMotionManager` exposes processed `CMDeviceMotion` data on Apple Watch, including `userAcceleration` and `rotationRate`. These values identify quick intentional motions without integrating acceleration into a drifting distance estimate.

`AVFAudio.AVAudioPlayer` plays bundled MP3 resources when a motion is accepted. `基础音效.mp3` is used for normal accepted gestures, and `强化音效.mp3` is used for the third consecutive accepted gesture.

## Architecture

### `MotionTriggerDetector`

A pure value-oriented detector owns threshold, cooldown, and combo behavior. Each sample contains acceleration magnitude, rotation magnitude, and timestamp. It returns whether one gesture should trigger audio, and which audio effect should play.

The starting rule accepts a motion when both adjusted thresholds are crossed and no accepted event has occurred during the previous `0.2` seconds. Accepted gestures within `1.5` seconds count as consecutive. The first two accepted gestures in a combo play the basic sound, and the third plays the enhanced sound before the combo resets. Sensitivity uses a `0...100` scale, where `100` is the most responsive setting; the app starts at `70` to reduce accidental triggers. This keeps the rule testable and prevents one wrist swing from producing repeated sounds.

### `MotionMonitor`

An observable, main-actor service owns one `CMMotionManager`, requests device-motion updates at approximately 100 Hz, transforms samples into detector input, and publishes:

- whether sensing is active or unavailable;
- latest normalized motion intensity;
- accepted trigger count;
- a user-adjustable sensitivity value.

It begins updates when the SwiftUI view appears and stops them when the view disappears. When the detector accepts a motion, it asks the audio service to play.

### `SoundPlayer`

An audio service loads bundled `基础音效.mp3` and `强化音效.mp3`, prepares an `AVAudioPlayer` for each resource, activates the audio session early, and plays effects at `1.15x`. `SoundPlaybackQueue` prevents overlap: if a trigger arrives during playback, the effect waits until the current sound finishes.

### `ContentView`

The watch screen replaces the template placeholder with:

- an active/unavailable status label;
- a prominent motion intensity indicator;
- a trigger counter;
- a sensitivity slider;
- a test-sound button for confirming audio without needing a motion event.

## Data Flow

1. `ContentView` appears and calls `MotionMonitor.start()`.
2. Core Motion delivers processed movement samples.
3. `MotionMonitor` calculates acceleration and rotation magnitudes and supplies them to `MotionTriggerDetector`.
4. The detector either rejects the sample or emits one trigger after its cooldown check.
5. On a trigger, `MotionMonitor` increments the count and tells `SoundPlayer` to play or queue the basic or enhanced sound returned by the detector.
6. `ContentView` observes published status and measurements and redraws the tuning UI.
7. When the view is no longer active, motion updates stop.

## Failure Behavior

- If device motion is unavailable, the UI reports that a physical Apple Watch is required and audio can still be tested manually.
- If the sound resource cannot be loaded or played, monitoring continues and the UI exposes an audio-unavailable message.
- Motion updates are stopped during teardown or view disappearance to avoid unnecessary sensor and battery use.

## Testing And Validation

- Unit-test detector behavior: a qualifying swing triggers; small motion does not; cooldown suppresses duplicates; sensitivity changes acceptance; fast follow-up gestures are accepted at maximum sensitivity.
- Unit-test playback queue behavior: active playback is not interrupted, and the next effect starts only after the current effect finishes.
- Build the watch app and test target with Xcode after implementation.
- Use the test-sound button to verify audio output.
- Validate gesture thresholds on a physical Apple Watch because the simulator cannot reproduce real wrist motion.

## GitHub Delivery

Initialize Git history on `main`, commit the confirmed design and implementation, create public repository `Qiiii1/Puncher`, and push `main` after local validation succeeds.

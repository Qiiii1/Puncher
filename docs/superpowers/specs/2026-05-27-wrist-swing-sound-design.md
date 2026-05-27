# Wrist Swing Sound Design

## Goal

Build a watchOS prototype that plays a short sound when the wearer makes a quick wrist-swing motion while the app is visible and active.

## Scope

- Monitor live Apple Watch motion only while the app is in the foreground.
- Detect a deliberate fast swing using motion intensity and rotation, not an estimated physical distance.
- Play one short, locally generated sound for each accepted gesture.
- Show monitoring state, latest intensity, trigger count, and a sensitivity control for on-wrist tuning.
- Publish the project in a public GitHub repository named `Puncher`.

The prototype does not monitor in the background, run a workout session, estimate centimeters of travel, classify swing direction, or persist analytics.

## Platform Capability

`CoreMotion.CMMotionManager` exposes processed `CMDeviceMotion` data on Apple Watch, including `userAcceleration` and `rotationRate`. These values identify quick intentional motions without integrating acceleration into a drifting distance estimate.

`AVFAudio.AVAudioPlayer` plays a short bundled WAV sound when a motion is accepted. The sound is generated for this project so it does not carry third-party licensing requirements.

## Architecture

### `MotionTriggerDetector`

A pure value-oriented detector owns threshold and cooldown behavior. Each sample contains acceleration magnitude, rotation magnitude, and timestamp. It returns whether one gesture should trigger audio.

The starting rule accepts a motion when both adjusted thresholds are crossed and no accepted event has occurred during the previous `0.35` seconds. Sensitivity adjusts the effective thresholds. This keeps the rule testable and prevents one wrist swing from producing repeated sounds.

### `MotionMonitor`

An observable, main-actor service owns one `CMMotionManager`, requests device-motion updates at approximately 50 Hz, transforms samples into detector input, and publishes:

- whether sensing is active or unavailable;
- latest normalized motion intensity;
- accepted trigger count;
- a user-adjustable sensitivity value.

It begins updates when the SwiftUI view appears and stops them when the view disappears. When the detector accepts a motion, it asks the audio service to play.

### `SoundPlayer`

An audio service loads the bundled `swing.wav`, prepares `AVAudioPlayer`, and restarts the short sound on each accepted gesture. The project includes a small generator source for the original sound asset so the resource can be reproduced.

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
5. On a trigger, `MotionMonitor` increments the count and tells `SoundPlayer` to play `swing.wav`.
6. `ContentView` observes published status and measurements and redraws the tuning UI.
7. When the view is no longer active, motion updates stop.

## Failure Behavior

- If device motion is unavailable, the UI reports that a physical Apple Watch is required and audio can still be tested manually.
- If the sound resource cannot be loaded or played, monitoring continues and the UI exposes an audio-unavailable message.
- Motion updates are stopped during teardown or view disappearance to avoid unnecessary sensor and battery use.

## Testing And Validation

- Unit-test detector behavior: a qualifying swing triggers; small motion does not; cooldown suppresses duplicates; sensitivity changes acceptance.
- Build the watch app and test target with Xcode after implementation.
- Use the test-sound button to verify audio output.
- Validate gesture thresholds on a physical Apple Watch because the simulator cannot reproduce real wrist motion.

## GitHub Delivery

Initialize Git history on `main`, commit the confirmed design and implementation, create public repository `Qiiii1/Puncher`, and push `main` after local validation succeeds.

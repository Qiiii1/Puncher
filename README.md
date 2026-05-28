# Puncher

Puncher is a small SwiftUI watchOS prototype: open the app, swing your wrist quickly, and the watch plays a short original sound effect.

## How It Works

- `Core Motion` supplies user acceleration and rotation-rate samples while the view is visible.
- `MotionTriggerDetector` accepts a fast intentional movement only when both motion thresholds are crossed.
- Motion updates run at `100 Hz`, and a `0.2` second cooldown keeps one swing from firing repeatedly without making quick follow-ups feel sluggish.
- Consecutive valid movements within `1.5` seconds form a combo: the first two play the basic sound, and the third plays the enhanced sound before the combo resets.
- The SwiftUI screen shows live intensity and trigger count, and lets you tune sensitivity from `0` to `100` on the watch. The prototype now starts at `100`.
- `AVAudioPlayer` plays `基础音效.mp3` and `强化音效.mp3` from `Puncher Watch App/AudioResource` at `1.15x`. If another trigger arrives while a sound is playing, it waits in a queue and starts after the current sound finishes.

The app detects motion intensity; it does not estimate the physical distance traveled by the wrist.

## Try It

1. Open the project in Xcode and run the `Puncher Watch App` scheme on an Apple Watch.
2. Open Puncher and tap **测试音效** to verify speaker output.
3. Swing your wrist firmly and adjust **灵敏度** until deliberate motions trigger consistently.

Motion sensing is active only while the app screen is open. A real watch is required to tune gesture feel because simulated motion cannot reproduce a wrist swing.

## Development Checks

Run the platform-independent detector and sound checks:

```bash
swiftc -parse-as-library -module-cache-path /private/tmp/PuncherModuleCache \
  'Puncher Watch App/MotionTriggerDetector.swift' \
  'Tests/Logic/MotionTriggerDetectorCheck.swift' \
  -o /private/tmp/motion-detector-check
/private/tmp/motion-detector-check

swiftc -parse-as-library -module-cache-path /private/tmp/PuncherModuleCache \
  'Tests/Logic/AudioResourceCheck.swift' \
  -o /private/tmp/audio-resource-check
/private/tmp/audio-resource-check 'Puncher Watch App/AudioResource'

swiftc -parse-as-library -module-cache-path /private/tmp/PuncherModuleCache \
  'Puncher Watch App/MotionTriggerDetector.swift' \
  'Puncher Watch App/SoundPlaybackQueue.swift' \
  'Tests/Logic/SoundPlaybackQueueCheck.swift' \
  -o /private/tmp/sound-playback-queue-check
/private/tmp/sound-playback-queue-check
```

Build the watch application and its test bundle without launching a simulator:

```bash
xcodebuild -project 'Puncher.xcodeproj' -target 'Puncher Watch App' \
  -configuration Debug -sdk watchsimulator CODE_SIGNING_ALLOWED=NO \
  OBJROOT=/private/tmp/PuncherWatchTargetBuild/Obj \
  SYMROOT=/private/tmp/PuncherWatchTargetBuild/Sym build
```

This checkout targets watchOS 26.2. To execute the app or the Xcode test bundle in Simulator, install a watchOS simulator runtime in Xcode Settings; on-wrist motion tuning still requires a physical Apple Watch.

# Puncher

Puncher is a small SwiftUI watchOS prototype: open the app, swing your wrist quickly, and the watch plays a short original sound effect.

## How It Works

- `Core Motion` supplies user acceleration and rotation-rate samples while the view is visible.
- `MotionTriggerDetector` accepts a fast intentional movement only when both motion thresholds are crossed.
- A `0.35` second cooldown prevents one swing from firing the sound repeatedly.
- The SwiftUI screen shows live intensity and trigger count, and lets you tune sensitivity on the watch.
- `AVAudioPlayer` plays `swing.wav`, generated locally by `Tools/generate_swing_sound.swift`.

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
  'Tests/Logic/SoundAssetCheck.swift' \
  -o /private/tmp/sound-asset-check
/private/tmp/sound-asset-check 'Puncher Watch App/Resources/swing.wav'
```

Build the watch application and its test bundle without launching a simulator:

```bash
xcodebuild -project 'Puncher.xcodeproj' -target 'Puncher Watch App' \
  -configuration Debug -sdk watchsimulator CODE_SIGNING_ALLOWED=NO \
  OBJROOT=/private/tmp/PuncherWatchTargetBuild/Obj \
  SYMROOT=/private/tmp/PuncherWatchTargetBuild/Sym build
```

This checkout targets watchOS 26.2. To execute the app or the Xcode test bundle in Simulator, install a watchOS simulator runtime in Xcode Settings; on-wrist motion tuning still requires a physical Apple Watch.

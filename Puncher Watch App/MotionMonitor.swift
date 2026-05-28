//
//  MotionMonitor.swift
//  Puncher Watch App
//
//  Created by Codex on 2026/5/27.
//

import Combine
import CoreMotion
import Foundation

@MainActor
final class MotionMonitor: ObservableObject {
    enum MonitoringState: Equatable {
        case idle
        case monitoring
        case unavailable
        case failed

        var title: String {
            switch self {
            case .idle:
                "待机"
            case .monitoring:
                "正在监听"
            case .unavailable:
                "动作传感器不可用"
            case .failed:
                "监听中断"
            }
        }

        var symbolName: String {
            switch self {
            case .idle:
                "pause.circle.fill"
            case .monitoring:
                "waveform.path.ecg"
            case .unavailable:
                "exclamationmark.triangle.fill"
            case .failed:
                "xmark.octagon.fill"
            }
        }
    }

    @Published private(set) var state: MonitoringState = .idle
    @Published private(set) var latestIntensity = 0.0
    @Published private(set) var triggerCount = 0
    @Published private(set) var audioMessage: String?
    @Published private(set) var runtimeMessage: String?
    @Published var sensitivity = MotionTriggerDetector.defaultSensitivity {
        didSet {
            detector.sensitivity = sensitivity
        }
    }

    private let motionManager: CMMotionManager
    private let soundPlayer: SoundPlayer
    private let runtimeController: ExtendedRuntimeController
    private var detector: MotionTriggerDetector

    init() {
        let soundPlayer = SoundPlayer()
        let runtimeController = ExtendedRuntimeController()
        motionManager = CMMotionManager()
        self.soundPlayer = soundPlayer
        self.runtimeController = runtimeController
        detector = MotionTriggerDetector(sensitivity: MotionTriggerDetector.defaultSensitivity)
        audioMessage = soundPlayer.errorMessage
        bindRuntimeController()
    }

    init(motionManager: CMMotionManager, soundPlayer: SoundPlayer) {
        let runtimeController = ExtendedRuntimeController()
        self.motionManager = motionManager
        self.soundPlayer = soundPlayer
        self.runtimeController = runtimeController
        detector = MotionTriggerDetector(sensitivity: MotionTriggerDetector.defaultSensitivity)
        audioMessage = soundPlayer.errorMessage
        bindRuntimeController()
    }

    func start() {
        guard !motionManager.isDeviceMotionActive else {
            return
        }
        guard motionManager.isDeviceMotionAvailable else {
            state = .unavailable
            return
        }

        state = .monitoring
        runtimeController.start()
        motionManager.deviceMotionUpdateInterval = 1.0 / 100.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            MainActor.assumeIsolated {
                guard let self else {
                    return
                }
                if error != nil {
                    self.state = .failed
                    return
                }
                guard let motion else {
                    return
                }
                self.process(motion)
            }
        }
    }

    func stop() {
        runtimeController.stop()
        motionManager.stopDeviceMotionUpdates()
        latestIntensity = 0.0
        if state == .monitoring {
            state = .idle
        }
    }

    func playTestSound() {
        if soundPlayer.play() {
            audioMessage = nil
        } else {
            audioMessage = soundPlayer.errorMessage ?? "音效播放失败。"
        }
    }

    private func process(_ motion: CMDeviceMotion) {
        let acceleration = motion.userAcceleration
        let rotation = motion.rotationRate
        let sample = MotionSample(
            accelerationX: acceleration.x,
            accelerationY: acceleration.y,
            accelerationZ: acceleration.z,
            rotationX: rotation.x,
            rotationY: rotation.y,
            rotationZ: rotation.z,
            timestamp: motion.timestamp
        )

        latestIntensity = detector.intensity(for: sample)
        guard let effect = detector.trigger(for: sample) else {
            return
        }

        triggerCount += 1
        if !soundPlayer.play(effect) {
            audioMessage = soundPlayer.errorMessage ?? "音效播放失败。"
        }
    }

    private func bindRuntimeController() {
        runtimeController.onMessageChange = { [weak self] message in
            self?.runtimeMessage = message
        }
    }
}

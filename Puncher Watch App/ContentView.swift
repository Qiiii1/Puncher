//
//  ContentView.swift
//  Puncher Watch App
//
//  Created by 李棋 on 2026/5/27.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var monitor = MotionMonitor()

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Label(monitor.state.title, systemImage: monitor.state.symbolName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)

                ProgressView(value: monitor.latestIntensity, total: 1.0) {
                    Text("动作强度")
                        .font(.caption)
                } currentValueLabel: {
                    Text(monitor.latestIntensity, format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit()
                }
                .tint(.orange)

                HStack {
                    Text("触发次数")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(monitor.triggerCount)")
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
                .font(.caption)

                VStack(spacing: 4) {
                    HStack {
                        Text("灵敏度")
                        Spacer()
                        Text("\(Int(monitor.sensitivity))")
                            .monospacedDigit()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Slider(value: $monitor.sensitivity, in: 0.0...100.0, step: 1.0)
                        .tint(.orange)
                }

                Button {
                    monitor.playTestSound()
                } label: {
                    Label("测试音效", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                if monitor.state == .unavailable {
                    Text("请在 Apple Watch 真机上测试挥动动作。")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if let audioMessage = monitor.audioMessage {
                    Text(audioMessage)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                if let runtimeMessage = monitor.runtimeMessage {
                    Text(runtimeMessage)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .onAppear {
            monitor.start()
        }
        .onDisappear {
            monitor.stop()
        }
    }

    private var statusColor: Color {
        switch monitor.state {
        case .idle:
            .secondary
        case .monitoring:
            .green
        case .unavailable, .failed:
            .orange
        }
    }
}

#Preview {
    ContentView()
}

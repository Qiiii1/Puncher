import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    FileHandle.standardError.write(Data("Usage: swift generate_swing_sound.swift <output.wav>\n".utf8))
    exit(EXIT_FAILURE)
}

let sampleRate: UInt32 = 44_100
let duration = 0.18
let sampleCount = Int(Double(sampleRate) * duration)
let channelCount: UInt16 = 1
let bitsPerSample: UInt16 = 16
let byteRate = sampleRate * UInt32(channelCount) * UInt32(bitsPerSample / 8)
let blockAlign = channelCount * (bitsPerSample / 8)

var samples = Data()
var phase = 0.0
var randomState: UInt32 = 0x00C0FFEE

func appendLittleEndian<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
    var littleEndian = value.littleEndian
    withUnsafeBytes(of: &littleEndian) {
        data.append(contentsOf: $0)
    }
}

func nextNoise() -> Double {
    randomState = 1_664_525 &* randomState &+ 1_013_904_223
    return Double(randomState) / Double(UInt32.max) * 2.0 - 1.0
}

for index in 0..<sampleCount {
    let progress = Double(index) / Double(sampleCount)
    let envelope = pow(1.0 - progress, 2.35)
    let frequency = 1_550.0 - 920.0 * progress
    phase += 2.0 * .pi * frequency / Double(sampleRate)

    let body = sin(phase) * 0.62
    let texture = nextNoise() * 0.38
    let value = min(max((body + texture) * envelope * 0.78, -1.0), 1.0)
    appendLittleEndian(Int16(value * Double(Int16.max)), to: &samples)
}

var wave = Data("RIFF".utf8)
appendLittleEndian(UInt32(36 + samples.count), to: &wave)
wave.append(Data("WAVE".utf8))
wave.append(Data("fmt ".utf8))
appendLittleEndian(UInt32(16), to: &wave)
appendLittleEndian(UInt16(1), to: &wave)
appendLittleEndian(channelCount, to: &wave)
appendLittleEndian(sampleRate, to: &wave)
appendLittleEndian(byteRate, to: &wave)
appendLittleEndian(blockAlign, to: &wave)
appendLittleEndian(bitsPerSample, to: &wave)
wave.append(Data("data".utf8))
appendLittleEndian(UInt32(samples.count), to: &wave)
wave.append(samples)

let outputURL = URL(fileURLWithPath: arguments[1])
try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try wave.write(to: outputURL, options: .atomic)
print("Generated \(outputURL.path) (\(sampleCount) samples)")

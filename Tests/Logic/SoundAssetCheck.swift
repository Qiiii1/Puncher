import Darwin
import Foundation

@main
struct SoundAssetCheck {

    static func main() {
        guard CommandLine.arguments.count == 2 else {
            fail("provide a WAV resource path")
        }

        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        guard let data = try? Data(contentsOf: url) else {
            fail("swing sound resource is missing")
        }

        require(data.count > 44, "sound resource should contain audio samples")
        require(asString(data, at: 0, count: 4) == "RIFF", "resource must be RIFF")
        require(asString(data, at: 8, count: 4) == "WAVE", "resource must be WAVE")
        require(asString(data, at: 12, count: 4) == "fmt ", "resource must contain PCM format")
        require(readUInt32(data, at: 24) == 44_100, "resource must use 44.1 kHz")
        require(readUInt16(data, at: 34) == 16, "resource must use 16-bit samples")

        let dataBytes = readUInt32(data, at: 40)
        let duration = Double(dataBytes) / Double(44_100 * 2)
        require(duration > 0.1 && duration < 0.3, "sound should be a short feedback burst")

        print("Sound asset checks passed")
    }

    private static func asString(_ data: Data, at offset: Int, count: Int) -> String {
        String(decoding: data[offset..<(offset + count)], as: UTF8.self)
    }

    private static func readUInt16(_ data: Data, at offset: Int) -> UInt16 {
        UInt16(data[offset]) | UInt16(data[offset + 1]) << 8
    }

    private static func readUInt32(_ data: Data, at offset: Int) -> UInt32 {
        UInt32(data[offset])
            | UInt32(data[offset + 1]) << 8
            | UInt32(data[offset + 2]) << 16
            | UInt32(data[offset + 3]) << 24
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            fail(message)
        }
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        exit(EXIT_FAILURE)
    }
}

import Darwin
import Foundation

@main
struct AudioResourceCheck {

    static func main() {
        guard CommandLine.arguments.count == 2 else {
            fail("provide the AudioResource directory path")
        }

        let directoryURL = URL(fileURLWithPath: CommandLine.arguments[1])
        checkMP3(named: "基础音效", in: directoryURL)
        checkMP3(named: "强化音效", in: directoryURL)
        print("Audio resource checks passed")
    }

    private static func checkMP3(named name: String, in directoryURL: URL) {
        let url = directoryURL.appendingPathComponent("\(name).mp3")
        guard let data = try? Data(contentsOf: url) else {
            fail("\(name).mp3 is missing")
        }

        require(data.count > 1_024, "\(name).mp3 should contain audio data")
        require(isMP3(data), "\(name).mp3 should look like an MP3 file")
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

    private static func isMP3(_ data: Data) -> Bool {
        let hasID3Header = data.count >= 3
            && data[0] == 0x49
            && data[1] == 0x44
            && data[2] == 0x33
        let hasFrameSync = data.count >= 2
            && data[0] == 0xFF
            && (data[1] & 0xE0) == 0xE0
        return hasID3Header || hasFrameSync
    }
}

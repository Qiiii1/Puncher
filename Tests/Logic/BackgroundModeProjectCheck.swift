import Darwin
import Foundation

@main
struct BackgroundModeProjectCheck {

    static func main() {
        guard CommandLine.arguments.count == 3 else {
            fail("provide the project.pbxproj path and Watch App Info.plist path")
        }

        let projectURL = URL(fileURLWithPath: CommandLine.arguments[1])
        guard let project = try? String(contentsOf: projectURL, encoding: .utf8) else {
            fail("could not read project file")
        }

        let infoPlistURL = URL(fileURLWithPath: CommandLine.arguments[2])
        guard let plistData = try? Data(contentsOf: infoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil),
              let dictionary = plist as? [String: Any] else {
            fail("could not read Watch App Info.plist")
        }
        let backgroundModes = dictionary["WKBackgroundModes"] as? [String] ?? []

        require(
            project.contains("INFOPLIST_FILE = \"Puncher Watch App/Info.plist\";"),
            "watch app target should use the explicit Info.plist"
        )
        require(
            project.contains("membershipExceptions = (\n\t\t\t\tInfo.plist,"),
            "Info.plist should be excluded from synchronized resource membership"
        )
        require(
            backgroundModes.contains("physical-therapy"),
            "Watch App Info.plist should enable the physical-therapy extended runtime background mode"
        )
        print("Background mode project checks passed")
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

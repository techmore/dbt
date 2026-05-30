import Foundation

final class TM_DBTLaunchMarker {
    static let shared = TM_DBTLaunchMarker()

    private init() {}

    func recordLaunch() {
        try? "launched\n".write(toFile: "/tmp/tm-dbt-launch.txt", atomically: true, encoding: .utf8)
    }
}

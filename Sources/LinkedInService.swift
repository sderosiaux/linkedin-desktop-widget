import Foundation

enum LinkedInService {
    private static let logFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".linkedin-widget.log")

    private static func log(_ msg: String) {
        let line = "\(Date()): \(msg)\n"
        if let fh = try? FileHandle(forWritingTo: logFile) {
            fh.seekToEndOfFile()
            fh.write(line.data(using: .utf8)!)
            fh.closeFile()
        } else {
            FileManager.default.createFile(atPath: logFile.path, contents: line.data(using: .utf8))
        }
    }

    private static var cachedPosts: [RankedPost] = []

    static func fetchTopPosts() -> [RankedPost] {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let bunPath = "\(homeDir)/.bun/bin"
        let tmpFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("linkedin-widget-\(ProcessInfo.processInfo.processIdentifier).json")

        var env = ProcessInfo.processInfo.environment
        let currentPath = env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        env["PATH"] = "\(bunPath):\(currentPath)"

        let process = Process()
        process.environment = env
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", "\(bunPath)/linkedin timeline --json -n 50 --min 0 > \(tmpFile.path)"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            let data = try Data(contentsOf: tmpFile)
            try? FileManager.default.removeItem(at: tmpFile)

            log("exit=\(process.terminationStatus) file=\(data.count)b")

            let posts = try JSONDecoder().decode([LinkedInPost].self, from: data)
            log("decoded \(posts.count) posts")

            let ranked = posts
                .map { RankedPost(from: $0) }
                .sorted { $0.score > $1.score }
            cachedPosts = ranked
            return ranked
        } catch {
            try? FileManager.default.removeItem(at: tmpFile)
            log("error: \(error), returning cached (\(cachedPosts.count) posts)")
            return cachedPosts
        }
    }
}

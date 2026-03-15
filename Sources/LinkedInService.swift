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

    private static func runCli(_ arguments: String) -> Data? {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let bunPath = "\(homeDir)/.bun/bin"
        let tmpFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("linkedin-widget-\(ProcessInfo.processInfo.processIdentifier)-\(Int.random(in: 0...999999)).json")

        var env = ProcessInfo.processInfo.environment
        let currentPath = env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        env["PATH"] = "\(bunPath):\(currentPath)"

        let process = Process()
        process.environment = env
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", "\(bunPath)/linkedin \(arguments) > \(tmpFile.path)"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = try Data(contentsOf: tmpFile)
            try? FileManager.default.removeItem(at: tmpFile)
            return data
        } catch {
            try? FileManager.default.removeItem(at: tmpFile)
            return nil
        }
    }

    static func fetchTopPosts() -> [RankedPost] {
        guard let data = runCli("timeline --json -n 50 --min 0") else {
            log("timeline: failed, returning cached (\(cachedPosts.count))")
            return cachedPosts
        }

        do {
            log("timeline: \(data.count)b")
            let posts = try JSONDecoder().decode([LinkedInPost].self, from: data)
            log("timeline: decoded \(posts.count) posts")
            let ranked = posts
                .map { RankedPost(from: $0) }
                .sorted { $0.score > $1.score }
            cachedPosts = ranked
            return ranked
        } catch {
            log("timeline: \(error), returning cached (\(cachedPosts.count))")
            return cachedPosts
        }
    }

    static func searchPosts(query: String) -> [RankedPost] {
        let escaped = query.replacingOccurrences(of: "'", with: "''")
        let sql = """
        SELECT p.id, \
        a.first_name || ' ' || a.last_name AS actorName, \
        COALESCE(a.headline, '') AS actorHeadline, \
        p.text, p.likes, \
        p.comments_count AS comments, \
        p.shares, \
        COALESCE(p.time_ago, '') AS timeAgo \
        FROM post p \
        JOIN author a ON p.author_urn = a.urn \
        WHERE p.text LIKE '%\(escaped)%' \
        OR a.first_name || ' ' || a.last_name LIKE '%\(escaped)%' \
        OR a.headline LIKE '%\(escaped)%' \
        ORDER BY p.likes + p.comments_count * 2 DESC \
        LIMIT 50
        """

        guard let data = runCli("db \"\(sql)\"") else {
            log("search: failed for '\(query)'")
            return []
        }

        do {
            let posts = try JSONDecoder().decode([LinkedInPost].self, from: data)
            log("search: '\(query)' -> \(posts.count) results")
            return posts
                .map { RankedPost(from: $0) }
                .sorted { $0.score > $1.score }
        } catch {
            log("search: \(error)")
            return []
        }
    }
}

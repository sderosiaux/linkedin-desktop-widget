import Foundation

enum LinkedInService {
    private static let logFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".linkedin-widget.log")

    private static func log(_ msg: String) {
        let line = "\(Date()): \(msg)\n"
        guard let data = line.data(using: .utf8) else { return }
        if let fh = try? FileHandle(forWritingTo: logFile) {
            fh.seekToEndOfFile()
            fh.write(data)
            fh.closeFile()
        } else {
            FileManager.default.createFile(atPath: logFile.path, contents: data)
        }
    }

    private static var cachedPosts: [RankedPost] = []

    private static func runCli(_ arguments: String) -> Data? {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let bunPath = "\(homeDir)/.bun/bin"
        let pid = ProcessInfo.processInfo.processIdentifier
        let rand = Int.random(in: 0...999_999)
        let tmpFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("linkedin-widget-\(pid)-\(rand).json")

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

    private static func runCliNoOutput(_ arguments: String) {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let bunPath = "\(homeDir)/.bun/bin"

        let process = Process()
        var env = ProcessInfo.processInfo.environment
        let currentPath = env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        env["PATH"] = "\(bunPath):\(currentPath)"
        process.environment = env
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", "\(bunPath)/linkedin \(arguments)"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            log("cli: \(arguments) -> exit \(process.terminationStatus)")
        } catch {
            log("cli: \(arguments) -> \(error)")
        }
    }

    static func dislikePost(_ postId: String) {
        runCliNoOutput("dislike \(postId)")
    }

    static func fetchTopPosts() -> [RankedPost] {
        guard let data = runCli("timeline --json -n 500 --min 0") else {
            log("timeline: failed, returning cached (\(cachedPosts.count))")
            return cachedPosts
        }

        do {
            log("timeline: \(data.count)b")
            let posts = try JSONDecoder().decode([LinkedInPost].self, from: data)
            log("timeline: decoded \(posts.count) posts")
            var seen = Set<String>()
            let ranked = posts
                .map { RankedPost(from: $0) }
                .sortedByDate()
                .filter { post in
                    let key = "\(post.actorName)|\(post.text.prefix(100))"
                    return seen.insert(key).inserted
                }
            cachedPosts = ranked
            return ranked
        } catch {
            log("timeline: \(error), returning cached (\(cachedPosts.count))")
            return cachedPosts
        }
    }

    static func searchPosts(query: String) -> [RankedPost] {
        let semantic = semanticSearch(query: query)
        if !semantic.isEmpty { return semantic }
        return sqlSearch(query: query)
    }

    private static func semanticSearch(query: String) -> [RankedPost] {
        let escaped = query.replacingOccurrences(of: "\"", with: "\\\"")
        guard let data = runCli("similar \"\(escaped)\" --json -n 30") else {
            log("semantic: failed for '\(query)'")
            return []
        }

        do {
            let posts = try JSONDecoder().decode([LinkedInPost].self, from: data)
            log("semantic: '\(query)' -> \(posts.count) results")
            return posts.map { RankedPost(from: $0) }.sortedByDate()
        } catch {
            log("semantic: \(error)")
            return []
        }
    }

    private static func sqlSearch(query: String) -> [RankedPost] {
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
        ORDER BY p.posted_at DESC \
        LIMIT 50
        """

        guard let data = runCli("db \"\(sql)\"") else {
            log("sql search: failed for '\(query)'")
            return []
        }

        do {
            let posts = try JSONDecoder().decode([LinkedInPost].self, from: data)
            log("sql search: '\(query)' -> \(posts.count) results")
            return posts.map { RankedPost(from: $0) }
        } catch {
            log("sql search: \(error)")
            return []
        }
    }
}

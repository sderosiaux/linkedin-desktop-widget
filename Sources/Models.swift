import Foundation

struct LinkedInPost: Codable {
    let id: String
    let actorName: String
    let actorHeadline: String
    let timeAgo: String
    let text: String
    let likes: Int
    let comments: Int
    let shares: Int
    let similarity: Double?
}

struct RankedPost: Identifiable {
    let id: String
    let actorName: String
    let actorHeadline: String
    let timeAgo: String
    let text: String
    let likes: Int
    let comments: Int
    let score: Double
    let similarity: Double?

    init(from post: LinkedInPost) {
        self.id = post.id
        self.actorName = post.actorName
        self.actorHeadline = post.actorHeadline
        self.timeAgo = post.timeAgo
        self.text = post.text
        self.likes = post.likes
        self.comments = post.comments
        self.similarity = post.similarity

        let engagement = Double(post.likes) + Double(post.comments) * 2.0
        let hours = Self.parseTimeAgoToHours(post.timeAgo)
        let decayWindow = 168.0
        let recencyBoost = max(0.0, (decayWindow - hours) / decayWindow) * 50.0
        self.score = engagement + recencyBoost
    }

    static func parseTimeAgoToHours(_ timeAgo: String) -> Double {
        let cleaned = timeAgo.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "")

        var digits = ""
        var unit = ""
        for ch in cleaned {
            if ch.isNumber {
                digits.append(ch)
            } else if ch != "•" {
                unit.append(ch)
            }
        }

        let value = Double(digits) ?? 0
        switch unit {
        case "h": return value
        case "d": return value * 24
        case "w": return value * 168
        case "mo": return value * 720
        case "y": return value * 8760
        default: return 168
        }
    }

    var isRecent: Bool {
        timeAgoHours < 4
    }

    var hasLink: Bool {
        text.contains("https://") || text.contains("http://")
    }

    var isLowValue: Bool {
        let stripped = text.replacingOccurrences(
            of: #"https?://\S+"#, with: "", options: .regularExpression
        )
        let wordCount = stripped.split(whereSeparator: { $0.isWhitespace }).count
        return wordCount < 5
    }

    var displayText: String {
        text.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
    }

    var postURL: URL? {
        URL(string: "https://www.linkedin.com/feed/update/urn:li:activity:\(id)/")
    }

    var timeAgoHours: Double {
        Self.parseTimeAgoToHours(timeAgo)
    }

    var contentKey: String {
        "\(actorName)|\(text.prefix(100))"
    }

    func matchesSearch(_ term: String) -> Bool {
        if term.isEmpty { return true }
        let lowered = term.lowercased()
        return actorName.lowercased().contains(lowered)
            || actorHeadline.lowercased().contains(lowered)
            || text.lowercased().contains(lowered)
    }
}

extension Array where Element == RankedPost {
    func sortedByDate() -> [RankedPost] {
        sorted { $0.timeAgoHours < $1.timeAgoHours }
    }
}

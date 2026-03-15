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
}

struct Topic: Identifiable, Hashable {
    let id: String
    let label: String
    let keywords: [String]

    static let all: [Topic] = [
        Topic(id: "kafka", label: "Kafka", keywords: [
            "kafka", "confluent", "tiered storage", "ksqldb", "ksql",
            "flink", "kafka connect", "avro", "schema registry",
            "conduktor", "redpanda", "kraft", "zookeeper",
        ]),
        Topic(id: "llm", label: "LLM", keywords: [
            "llm", "gpt", "claude", "openai", "anthropic", "langchain",
            "rag", "fine-tuning", "fine tuning", "transformer", "prompt engineering",
            "ai agent", "copilot", "gemini", "mistral", "ollama",
            "mcp", "model context protocol",
        ]),
        Topic(id: "streaming", label: "Streaming", keywords: [
            "streaming", "real-time", "realtime", "event-driven", "event driven",
            "pub/sub", "pubsub", "pulsar", "kinesis", "nats",
            "stream processing", "cep",
        ]),
        Topic(id: "data", label: "Data", keywords: [
            "data engineering", "data mesh", "data pipeline", "lakehouse",
            "iceberg", "spark", "airflow", "dbt", "data lake",
            "snowflake", "databricks", "delta lake", "parquet",
        ]),
        Topic(id: "platform", label: "Platform", keywords: [
            "kubernetes", "k8s", "docker", "terraform", "platform engineering",
            "devops", "sre", "observability", "grafana", "prometheus",
            "infrastructure", "cloud native",
        ]),
    ]
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
    let matchedTopics: Set<String>

    init(from post: LinkedInPost) {
        self.id = post.id
        self.actorName = post.actorName
        self.actorHeadline = post.actorHeadline
        self.timeAgo = post.timeAgo
        self.text = post.text
        self.likes = post.likes
        self.comments = post.comments

        let engagement = Double(post.likes) + Double(post.comments) * 2.0
        let hours = RankedPost.parseTimeAgoToHours(post.timeAgo)
        let decayWindow = 168.0
        let recencyBoost = max(0.0, (decayWindow - hours) / decayWindow) * 50.0
        self.score = engagement + recencyBoost

        let searchable = "\(post.text) \(post.actorHeadline)".lowercased()
        var matched = Set<String>()
        for topic in Topic.all {
            if topic.keywords.contains(where: { searchable.contains($0) }) {
                matched.insert(topic.id)
            }
        }
        self.matchedTopics = matched
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

    var hasLink: Bool {
        text.contains("https://") || text.contains("http://")
    }

    var displayText: String {
        text.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
    }

    var postURL: URL {
        URL(string: "https://www.linkedin.com/feed/update/urn:li:activity:\(id)/")!
    }

    func matchesSearch(_ query: String) -> Bool {
        if query.isEmpty { return true }
        let q = query.lowercased()
        return actorName.lowercased().contains(q)
            || actorHeadline.lowercased().contains(q)
            || text.lowercased().contains(q)
    }
}

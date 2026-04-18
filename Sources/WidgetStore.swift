import Combine
import Foundation

final class WidgetStore: ObservableObject {
    @Published var allPosts: [RankedPost] = []
    @Published var searchResults: [RankedPost]?
    @Published var lastRefresh: Date?
    @Published var searchQuery: String = "" {
        didSet { scheduleSearch() }
    }
    @Published var isSearching = false
    @Published var showHidden = false
    @Published var hiddenKeys: Set<String> = []


    private static let hiddenFile: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/share/linkedin-widget")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("hidden.json")
    }()

    var posts: [RankedPost] {
        let source = searchQuery.isEmpty ? allPosts : (searchResults ?? [])
        let visible = showHidden ? source : source.filter { !hiddenKeys.contains($0.contentKey) && !$0.isLowValue }
        return searchQuery.isEmpty ? Array(visible.prefix(50)) : visible
    }

    var hiddenCount: Int { hiddenKeys.count }

    private var searchTask: Task<Void, Never>?

    init() {
        loadHidden()
    }

    func hidePost(_ post: RankedPost) {
        hiddenKeys.insert(post.contentKey)
        saveHidden()
    }

    func unhideAll() {
        hiddenKeys.removeAll()
        saveHidden()
    }

    private func loadHidden() {
        guard let data = try? Data(contentsOf: Self.hiddenFile) else { return }
        // Support both old format (Set<String> of IDs) and new format (Set<String> of content keys)
        if let keys = try? JSONDecoder().decode(Set<String>.self, from: data) {
            hiddenKeys = keys
        }
    }

    private func saveHidden() {
        guard let data = try? JSONEncoder().encode(hiddenKeys) else { return }
        try? data.write(to: Self.hiddenFile)
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        let query = searchQuery

        if query.isEmpty {
            searchResults = nil
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }

            let results = await Task.detached {
                LinkedInService.searchPosts(query: query)
            }.value

            guard !Task.isCancelled else { return }
            self.searchResults = results
            self.isSearching = false
        }
    }

    func dislikePost(_ post: RankedPost) {
        hidePost(post)
        Task.detached {
            LinkedInService.dislikePost(post.id)
        }
    }

    @MainActor
    func refresh() async {
        let result = await Task.detached {
            LinkedInService.fetchTopPosts()
        }.value
        self.allPosts = result
        self.lastRefresh = Date()
    }
}

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
    @Published var hiddenIds: Set<String> = []

    private static let hiddenFile: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/share/linkedin-widget")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("hidden.json")
    }()

    var posts: [RankedPost] {
        let source = searchQuery.isEmpty ? allPosts : (searchResults ?? [])
        if showHidden { return source }
        return source.filter { !hiddenIds.contains($0.id) }
    }

    var hiddenCount: Int { hiddenIds.count }

    private var searchTask: Task<Void, Never>?

    init() {
        loadHidden()
    }

    func hidePost(_ id: String) {
        hiddenIds.insert(id)
        saveHidden()
    }

    func unhideAll() {
        hiddenIds.removeAll()
        saveHidden()
    }

    private func loadHidden() {
        guard let data = try? Data(contentsOf: Self.hiddenFile),
              let ids = try? JSONDecoder().decode(Set<String>.self, from: data)
        else { return }
        hiddenIds = ids
    }

    private func saveHidden() {
        guard let data = try? JSONEncoder().encode(hiddenIds) else { return }
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

    func dislikePost(_ id: String) {
        hidePost(id)
        Task.detached {
            LinkedInService.dislikePost(id)
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

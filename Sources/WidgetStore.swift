import Foundation
import Observation

@Observable
final class WidgetStore {
    var allPosts: [RankedPost] = []
    var searchResults: [RankedPost]? = nil
    var lastRefresh: Date? = nil
    var searchQuery: String = "" {
        didSet { scheduleSearch() }
    }
    var isSearching = false

    var posts: [RankedPost] {
        if searchQuery.isEmpty {
            return allPosts
        }
        return searchResults ?? []
    }

    private var searchTask: Task<Void, Never>?

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

    @MainActor
    func refresh() async {
        let result = await Task.detached {
            LinkedInService.fetchTopPosts()
        }.value
        self.allPosts = result
        self.lastRefresh = Date()
    }
}

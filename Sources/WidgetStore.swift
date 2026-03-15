import Foundation
import Observation

@Observable
final class WidgetStore {
    var allPosts: [RankedPost] = []
    var lastRefresh: Date? = nil
    var searchQuery: String = ""

    var posts: [RankedPost] {
        allPosts.filter { $0.matchesSearch(searchQuery) }
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

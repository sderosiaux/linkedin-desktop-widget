import SwiftUI

struct WidgetView: View {
    let store: WidgetStore
    let timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            searchField
            Divider()
            contentSection
            ResizeHandle()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await store.refresh() }
        .onReceive(timer) { _ in
            Task { await store.refresh() }
        }
    }

    private var headerSection: some View {
        HStack(spacing: 6) {
            Text("LinkedIn")
                .font(.headline)
                .fontWeight(.bold)
            if store.hiddenCount > 0 {
                Button(
                    action: { store.showHidden.toggle() },
                    label: {
                        Text("\(store.hiddenCount) hidden")
                            .font(.caption2)
                            .foregroundStyle(store.showHidden ? Color.blue : Color.secondary)
                    }
                )
                .buttonStyle(.plain)
            }
            Spacer()
            if let date = store.lastRefresh {
                Text(date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            headerMenu
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var headerMenu: some View {
        Menu {
            Button("Refresh") {
                Task { await store.refresh() }
            }
            if store.hiddenCount > 0 {
                Button("Unhide all (\(store.hiddenCount))") {
                    store.unhideAll()
                }
            }
            Divider()
            Button("Quit") {
                NSApp.terminate(nil)
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.caption)
                .foregroundStyle(.tertiary)
            TextField("Filter by name, company, keyword...", text: Binding(
                get: { store.searchQuery },
                set: { store.searchQuery = $0 }
            ))
            .textFieldStyle(.plain)
            .font(.caption)
            if !store.searchQuery.isEmpty {
                Button(
                    action: { store.searchQuery = "" },
                    label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                )
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.04))
    }

    @ViewBuilder
    private var contentSection: some View {
        if store.isSearching {
            Spacer()
            ProgressView()
                .scaleEffect(0.7)
                .frame(maxWidth: .infinity)
            Spacer()
        } else if store.posts.isEmpty {
            Spacer()
            Text(store.allPosts.isEmpty
                 ? "No posts yet.\nRun: linkedin sync"
                 : "No matches in DB.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.posts) { post in
                        PostRow(post: post, store: store)
                        if post.id != store.posts.last?.id {
                            Divider().padding(.leading, 12)
                        }
                    }
                }
            }
        }
    }
}

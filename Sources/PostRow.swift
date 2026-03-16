import SwiftUI

struct PostRow: View {
    let post: RankedPost
    @ObservedObject var store: WidgetStore
    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            postContent
            if isHovered {
                hoverActions
            }
        }
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var postContent: some View {
        Button(
            action: {
                if let url = post.postURL {
                    NSWorkspace.shared.open(url)
                }
            },
            label: {
                VStack(alignment: .leading, spacing: 4) {
                    postHeader
                    Text(post.displayText)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                    postStats
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
        )
        .buttonStyle(.plain)
    }

    private var postHeader: some View {
        HStack(spacing: 4) {
            if post.isRecent {
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)
            }
            Text(post.actorName)
                .font(.body)
                .fontWeight(.semibold)
                .lineLimit(1)
            Spacer()
            if post.hasLink {
                Image(systemName: "link")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Text(post.timeAgo)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var postStats: some View {
        HStack(spacing: 12) {
            Label("\(post.likes)", systemImage: "heart")
            Label("\(post.comments)", systemImage: "bubble.right")
            if let sim = post.similarity {
                Spacer()
                Text("\(Int(sim * 100))%")
                    .font(.caption)
                    .foregroundStyle(.blue.opacity(0.7))
            }
        }
        .font(.caption)
        .foregroundStyle(.tertiary)
    }

    private var hoverActions: some View {
        HStack(spacing: 4) {
            hoverButton("Read") {
                store.hidePost(post.id)
            }
            hoverButton("Not for me") {
                store.dislikePost(post.id)
            }
            hoverButton("More like this") {
                store.searchQuery = post.displayText.prefix(80).description
            }
        }
        .padding(4)
    }

    private func hoverButton(
        _ label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }
}

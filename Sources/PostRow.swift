import SwiftUI

struct PostRow: View {
    let post: RankedPost
    @State private var isHovered = false

    var body: some View {
        Button(
            action: {
                if let url = post.postURL {
                    NSWorkspace.shared.open(url)
                }
            },
            label: { postContent }
        )
        .buttonStyle(.plain)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var postContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            postHeader
            Text(post.displayText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            postStats
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var postHeader: some View {
        HStack {
            Text(post.actorName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
            Spacer()
            if post.hasLink {
                Image(systemName: "link")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text(post.timeAgo)
                .font(.caption2)
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
                    .font(.caption2)
                    .foregroundStyle(.blue.opacity(0.7))
            }
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }
}

import SwiftUI

struct PostRow: View {
    let post: RankedPost
    @State private var isHovered = false

    var body: some View {
        Button(action: { NSWorkspace.shared.open(post.postURL) }) {
            VStack(alignment: .leading, spacing: 4) {
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

                Text(post.displayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                HStack(spacing: 12) {
                    Label("\(post.likes)", systemImage: "heart")
                    Label("\(post.comments)", systemImage: "bubble.right")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

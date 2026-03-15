import SwiftUI
import AppKit

struct ResizeHandle: View {
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.primary.opacity(0.25))
                .frame(width: 36, height: 3)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onHover { inside in
                    if inside {
                        NSCursor.resizeUpDown.push()
                    } else {
                        NSCursor.pop()
                    }
                }
        }
    }
}

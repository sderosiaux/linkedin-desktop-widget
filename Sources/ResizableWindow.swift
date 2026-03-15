import AppKit

class ResizableWindow: NSWindow {
    override var canBecomeKey: Bool { true }

    func addResizeBar() {
        guard let content = contentView else { return }
        let bar = ResizeBarView()
        bar.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            bar.heightAnchor.constraint(equalToConstant: 20),
        ])
    }
}

class ResizeBarView: NSView {
    override var mouseDownCanMoveWindow: Bool { false }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .resizeUpDown)
    }

    override func mouseDown(with event: NSEvent) {
        guard let window = self.window else { return }
        let startFrame = window.frame
        let startMouse = window.convertPoint(toScreen: event.locationInWindow)

        var keepRunning = true
        while keepRunning {
            guard let event = NSApp.nextEvent(
                matching: [.leftMouseDragged, .leftMouseUp],
                until: .distantFuture,
                inMode: .eventTracking,
                dequeue: true
            ) else { continue }

            switch event.type {
            case .leftMouseDragged:
                let currentMouse = window.convertPoint(toScreen: event.locationInWindow)
                let deltaY = startMouse.y - currentMouse.y
                var newHeight = startFrame.height + deltaY
                newHeight = max(window.minSize.height, min(window.maxSize.height, newHeight))

                let newOrigin = NSPoint(
                    x: startFrame.origin.x,
                    y: startFrame.maxY - newHeight
                )
                window.setFrame(
                    NSRect(origin: newOrigin, size: NSSize(width: startFrame.width, height: newHeight)),
                    display: true
                )

            case .leftMouseUp:
                keepRunning = false
                window.saveFrame(usingName: window.frameAutosaveName)

            default:
                break
            }
        }
    }
}

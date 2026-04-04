import AppKit
import Combine
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let store = WidgetStore()
    private var statusItem: NSStatusItem?
    private var cancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let contentView = WidgetView(store: store)
        let hostingView = NSHostingView(rootView: contentView)

        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 16
        visualEffect.layer?.masksToBounds = true

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
        ])

        window = ResizableWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 480),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = visualEffect
        window.minSize = NSSize(width: 260, height: 200)
        window.maxSize = NSSize(width: 600, height: 1200)
        window.acceptsMouseMovedEvents = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isMovableByWindowBackground = true
        if let resizable = window as? ResizableWindow {
            resizable.addResizeCorner()
        }
        window.setFrameAutosaveName("LinkedInWidget")

        if !window.setFrameUsingName("LinkedInWidget") {
            if let screen = NSScreen.main {
                let rect = screen.visibleFrame
                window.setFrameOrigin(NSPoint(x: rect.maxX - 340, y: rect.maxY - 500))
            }
        }

        window.orderFront(nil)

        setupEditMenu()
        setupStatusBar()
    }

    // MARK: - Status bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }
        button.action = #selector(toggleWindow)
        button.target = self
        updateStatusButton(button, unread: 0)

        cancellable = Publishers.CombineLatest(store.$allPosts, store.$hiddenKeys)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] posts, hidden in
                guard let button = self?.statusItem?.button else { return }
                let unread = posts.filter { !hidden.contains($0.contentKey) }.count
                self?.updateStatusButton(button, unread: unread)
            }
    }

    private func updateStatusButton(_ button: NSStatusBarButton, unread: Int) {
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(string: "LinkedIn ", attributes: [
            .foregroundColor: NSColor.labelColor,
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
        ]))
        if unread > 0 {
            result.append(NSAttributedString(string: "\(unread)", attributes: [
                .foregroundColor: NSColor.systemBlue,
                .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium),
            ]))
        } else {
            result.append(NSAttributedString(string: "●", attributes: [
                .foregroundColor: NSColor.systemGreen,
                .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            ]))
        }
        button.attributedTitle = result
    }

    @objc private func toggleWindow() {
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Edit menu

    private func setupEditMenu() {
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let editItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        editItem.submenu = editMenu

        let mainMenu = NSMenu()
        mainMenu.addItem(editItem)
        NSApp.mainMenu = mainMenu
    }
}

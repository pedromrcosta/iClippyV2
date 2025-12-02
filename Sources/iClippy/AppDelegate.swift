import AppKit
import SwiftUI

/// Application delegate that manages the clipboard monitor, hotkey, and history window
class AppDelegate: NSObject, NSApplicationDelegate {
    private var dbManager: DBManager!
    private var clipboardMonitor: ClipboardMonitor!
    private var hotKeyManager: HotKeyManager!
    private var historyPanel: NSPanel?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize managers
        dbManager = DBManager.defaultManager()
        clipboardMonitor = ClipboardMonitor(dbManager: dbManager)
        hotKeyManager = HotKeyManager()
        
        // Start monitoring clipboard
        clipboardMonitor.start()
        
        // Register global hotkey (Option+V)
        hotKeyManager.registerHotKey()
        
        // Listen for hotkey notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(toggleHistoryWindow),
            name: HotKeyManager.showHistoryNotification,
            object: nil
        )
        
        print("iClippy started!")
        print("Database location: \(dbManager.databasePath())")
        print("Press Option+V to show clipboard history")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stop()
        hotKeyManager.unregisterHotKey()
    }
    
    @objc private func toggleHistoryWindow() {
        if let panel = historyPanel, panel.isVisible {
            panel.orderOut(nil)
            historyPanel = nil
        } else {
            showHistoryWindow()
        }
    }
    
    private func showHistoryWindow() {
        // Create SwiftUI view with view model
        let viewModel = HistoryViewModel(dbManager: dbManager)
        let historyView = HistoryView(viewModel: viewModel)
        
        // Create hosting view
        let hostingView = NSHostingView(rootView: historyView)
        
        // Create panel
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        panel.title = "Clipboard History"
        panel.contentView = hostingView
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        
        // Activate the app to bring window to front
        NSApp.activate(ignoringOtherApps: true)
        
        // Store panel reference
        self.historyPanel = panel
    }
}

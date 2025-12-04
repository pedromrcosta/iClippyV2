import AppKit
import SwiftUI

/// Application delegate that manages the clipboard monitor, hotkey, and history window
class AppDelegate: NSObject, NSApplicationDelegate {
    private static let historyPanelIdentifier = "com.iclippy.macos.historyPanel"
    
    private var dbManager: DBManager!
    private var clipboardMonitor: ClipboardMonitor!
    private var hotKeyManager: HotKeyManager!
    private var statusBarManager: StatusBarManager!
    private var historyPanel: NSPanel?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize managers
        dbManager = DBManager.defaultManager()
        clipboardMonitor = ClipboardMonitor(dbManager: dbManager)
        hotKeyManager = HotKeyManager()
        
        // Initialize status bar with callbacks
        statusBarManager = StatusBarManager(
            dbManager: dbManager,
            onShowHistory: { [weak self] in
                self?.toggleHistoryWindow()
            },
            onShortcutChanged: { [weak self] in
                self?.hotKeyManager.registerHotKey()
            }
        )
        statusBarManager.setupStatusBar()
        
        // Start monitoring clipboard
        clipboardMonitor.start()
        
        // Register global hotkey (configurable via settings)
        hotKeyManager.registerHotKey()
        
        // Listen for hotkey notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(toggleHistoryWindow),
            name: HotKeyManager.showHistoryNotification,
            object: nil
        )
        
        let settingsManager = SettingsManager.shared
        print("iClippy started!")
        print("Database location: \(dbManager.databasePath())")
        print("Current hotkey: \(settingsManager.getHotKeyDescription())")
        print("Status bar icon added - click to access settings")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stop()
        hotKeyManager.unregisterHotKey()
        statusBarManager.removeStatusBar()
    }
    
    @objc private func toggleHistoryWindow() {
        if let panel = historyPanel, panel.isVisible {
            print("[DEBUG] Closing clipboard history window")
            panel.orderOut(nil)
            historyPanel = nil
        } else {
            showHistoryWindow()
        }
    }
    
    private func showHistoryWindow() {
        print("[DEBUG] Showing clipboard history window")
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
        
        // Set window identifiers to fix "Cannot index window tabs" warning
        panel.tabbingMode = .disallowed
        panel.tabbingIdentifier = Self.historyPanelIdentifier
        panel.identifier = NSUserInterfaceItemIdentifier(Self.historyPanelIdentifier)
        panel.frameAutosaveName = "iClippyHistoryPanelFrame"
        
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        
        // Activate the app to bring window to front
        NSApp.activate(ignoringOtherApps: true)
        
        // Store panel reference
        self.historyPanel = panel
    }
}

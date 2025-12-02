import AppKit
import Foundation

/// Monitors the system clipboard for text changes
class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount: Int
    private let dbManager: DBManager
    private let pollInterval: TimeInterval
    
    init(dbManager: DBManager, pollInterval: TimeInterval = 0.5) {
        self.dbManager = dbManager
        self.pollInterval = pollInterval
        self.lastChangeCount = NSPasteboard.general.changeCount
    }
    
    /// Start monitoring the clipboard
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    /// Stop monitoring the clipboard
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        // Only process if the clipboard has changed
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        // Only record text items
        if let text = pasteboard.string(forType: .string) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                dbManager.add(text: trimmed)
            }
        }
    }
}

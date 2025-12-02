import SwiftUI

/// Main entry point for the iClippy clipboard history app
@main
struct iClippyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Empty scene since we use NSPanel for the history window
        Settings {
            EmptyView()
        }
    }
}

import AppKit
import Carbon

/// Manages global hotkey registration (Option+V)
class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    static let showHistoryNotification = Notification.Name("ShowHistoryWindow")
    
    func registerHotKey() {
        var gMyHotKeyID = EventHotKeyID()
        // Using FourCC for "clip"
        gMyHotKeyID.signature = 0x636C6970 // "clip" in ASCII hex
        gMyHotKeyID.id = 1
        
        // Option+V: keyCode 9 is 'V', optionKey modifier
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        
        let callback: EventHandlerUPP = { (nextHandler, theEvent, userData) -> OSStatus in
            NotificationCenter.default.post(name: HotKeyManager.showHistoryNotification, object: nil)
            return noErr
        }
        
        InstallEventHandler(GetApplicationEventTarget(), callback, 1, &eventType, nil, &eventHandler)
        
        let keyCode: UInt32 = 9 // 'V' key
        let modifiers: UInt32 = UInt32(optionKey)
        
        RegisterEventHotKey(keyCode, modifiers, gMyHotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
    
    func unregisterHotKey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
    
    deinit {
        unregisterHotKey()
    }
}

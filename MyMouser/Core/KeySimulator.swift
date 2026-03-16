import Foundation
import CoreGraphics
import AppKit

// MARK: - Key Codes (macOS)
struct KeyCodes {
    static let kVK_Command: CGKeyCode = 0x37
    static let kVK_Shift: CGKeyCode = 0x38
    static let kVK_Option: CGKeyCode = 0x3A
    static let kVK_Control: CGKeyCode = 0x3B
    static let kVK_Tab: CGKeyCode = 0x30
    static let kVK_Space: CGKeyCode = 0x31
    static let kVK_Return: CGKeyCode = 0x24
    static let kVK_Delete: CGKeyCode = 0x33
    static let kVK_ForwardDelete: CGKeyCode = 0x75
    static let kVK_Escape: CGKeyCode = 0x35
    static let kVK_LeftArrow: CGKeyCode = 0x7B
    static let kVK_RightArrow: CGKeyCode = 0x7C
    static let kVK_DownArrow: CGKeyCode = 0x7D
    static let kVK_UpArrow: CGKeyCode = 0x7E
    
    static let kVK_ANSI_A: CGKeyCode = 0x00
    static let kVK_ANSI_S: CGKeyCode = 0x01
    static let kVK_ANSI_D: CGKeyCode = 0x02
    static let kVK_ANSI_F: CGKeyCode = 0x03
    static let kVK_ANSI_N: CGKeyCode = 0x2D
    static let kVK_ANSI_T: CGKeyCode = 0x11
    static let kVK_ANSI_W: CGKeyCode = 0x0D
    static let kVK_ANSI_X: CGKeyCode = 0x07
    static let kVK_ANSI_C: CGKeyCode = 0x08
    static let kVK_ANSI_V: CGKeyCode = 0x09
    static let kVK_ANSI_Z: CGKeyCode = 0x06
    static let kVK_ANSI_LeftBracket: CGKeyCode = 0x21
    static let kVK_ANSI_RightBracket: CGKeyCode = 0x1E
}

// MARK: - Action Definition
struct Action {
    let label: String
    let keys: [CGKeyCode]
    let category: String
    let macFn: Int?  // For media keys
}

// MARK: - Actions Dictionary
let actions: [String: Action] = [
    "alt_tab": Action(
        label: "Cmd + Tab (Switch Windows)",
        keys: [KeyCodes.kVK_Command, KeyCodes.kVK_Tab],
        category: "Navigation",
        macFn: nil
    ),
    "alt_shift_tab": Action(
        label: "Cmd + Shift + Tab (Switch Windows Reverse)",
        keys: [KeyCodes.kVK_Command, KeyCodes.kVK_Shift, KeyCodes.kVK_Tab],
        category: "Navigation",
        macFn: nil
    ),
    "browser_back": Action(
        label: "Browser Back (Cmd+[)",
        keys: [KeyCodes.kVK_Command, KeyCodes.kVK_ANSI_LeftBracket],
        category: "Browser",
        macFn: nil
    ),
    "browser_forward": Action(
        label: "Browser Forward (Cmd+])",
        keys: [KeyCodes.kVK_Command, KeyCodes.kVK_ANSI_RightBracket],
        category: "Browser",
        macFn: nil
    ),
    "copy": Action(
        label: "Copy (Cmd+C)",
        keys: [KeyCodes.kVK_Command, KeyCodes.kVK_ANSI_C],
        category: "Editing",
        macFn: nil
    ),
    "paste": Action(
        label: "Paste (Cmd+V)",
        keys: [KeyCodes.kVK_Command, KeyCodes.kVK_ANSI_V],
        category: "Editing",
        macFn: nil
    ),
    "cut": Action(
        label: "Cut (Cmd+X)",
        keys: [KeyCodes.kVK_Command, KeyCodes.kVK_ANSI_X],
        category: "Editing",
        macFn: nil
    ),
    "undo": Action(
        label: "Undo (Cmd+Z)",
        keys: [KeyCodes.kVK_Command, KeyCodes.kVK_ANSI_Z],
        category: "Editing",
        macFn: nil
    ),
    "select_all": Action(
        label: "Select All (Cmd+A)",
        keys: [KeyCodes.kVK_Command, KeyCodes.kVK_ANSI_A],
        category: "Editing",
        macFn: nil
    ),
    "save": Action(
        label: "Save (Cmd+S)",
        keys: [KeyCodes.kVK_Command, KeyCodes.kVK_ANSI_S],
        category: "Editing",
        macFn: nil
    ),
    "close_tab": Action(
        label: "Close Tab (Cmd+W)",
        keys: [KeyCodes.kVK_Command, KeyCodes.kVK_ANSI_W],
        category: "Browser",
        macFn: nil
    ),
    "new_tab": Action(
        label: "New Tab (Cmd+T)",
        keys: [KeyCodes.kVK_Command, KeyCodes.kVK_ANSI_T],
        category: "Browser",
        macFn: nil
    ),
    "find": Action(
        label: "Find (Cmd+F)",
        keys: [KeyCodes.kVK_Command, KeyCodes.kVK_ANSI_F],
        category: "Editing",
        macFn: nil
    ),
    "win_d": Action(
        label: "Mission Control (Ctrl+Up)",
        keys: [KeyCodes.kVK_Control, KeyCodes.kVK_UpArrow],
        category: "Navigation",
        macFn: nil
    ),
    "task_view": Action(
        label: "Mission Control (Ctrl+Up)",
        keys: [KeyCodes.kVK_Control, KeyCodes.kVK_UpArrow],
        category: "Navigation",
        macFn: nil
    ),
    "volume_up": Action(
        label: "Volume Up",
        keys: [],
        category: "Media",
        macFn: 0  // NX_KEYTYPE_SOUND_UP
    ),
    "volume_down": Action(
        label: "Volume Down",
        keys: [],
        category: "Media",
        macFn: 1  // NX_KEYTYPE_SOUND_DOWN
    ),
    "volume_mute": Action(
        label: "Volume Mute",
        keys: [],
        category: "Media",
        macFn: 7  // NX_KEYTYPE_MUTE
    ),
    "play_pause": Action(
        label: "Play / Pause",
        keys: [],
        category: "Media",
        macFn: 16  // NX_KEYTYPE_PLAY
    ),
    "next_track": Action(
        label: "Next Track",
        keys: [],
        category: "Media",
        macFn: 17  // NX_KEYTYPE_NEXT
    ),
    "prev_track": Action(
        label: "Previous Track",
        keys: [],
        category: "Media",
        macFn: 18  // NX_KEYTYPE_PREVIOUS
    ),
    "none": Action(
        label: "Do Nothing (Pass-through)",
        keys: [],
        category: "Other",
        macFn: nil
    ),
]

// MARK: - Modifier Flags Mapping
let modifierFlags: [CGKeyCode: CGEventFlags] = [
    KeyCodes.kVK_Command: .maskCommand,
    KeyCodes.kVK_Shift: .maskShift,
    KeyCodes.kVK_Option: .maskAlternate,
    KeyCodes.kVK_Control: .maskControl,
]

// MARK: - KeySimulator
class KeySimulator {
    
    static func sendKeyCombo(keys: [CGKeyCode], holdMs: Int = 50) {
        guard !keys.isEmpty else { return }
        
        // Calculate modifier flags
        var flags: CGEventFlags = []
        for key in keys {
            if let flag = modifierFlags[key] {
                flags.insert(flag)
            }
        }
        
        // Press all keys
        for key in keys {
            let event = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: true)
            event?.flags = flags
            event?.post(tap: .cghidEventTap)
        }
        
        // Hold
        if holdMs > 0 {
            usleep(useconds_t(holdMs * 1000))
        }
        
        // Release in reverse order
        for key in keys.reversed() {
            let event = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: false)
            event?.post(tap: .cghidEventTap)
        }
    }
    
    static func sendMediaKey(keyId: Int) {
        // Use NSEvent to send media keys
        let modifierFlagsDown: NSEvent.ModifierFlags = [.function, .init(rawValue: 0xa00)]
        let modifierFlagsUp: NSEvent.ModifierFlags = [.function, .init(rawValue: 0xb00)]
        
        let data1Down = (keyId << 16) | (0xa << 8)
        let data1Up = (keyId << 16) | (0xb << 8)
        
        if let evDown = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: modifierFlagsDown,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: data1Down,
            data2: -1
        ), let evUp = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: modifierFlagsUp,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: data1Up,
            data2: -1
        ) {
            if let cgDown = evDown.cgEvent, let cgUp = evUp.cgEvent {
                cgDown.post(tap: .cghidEventTap)
                cgUp.post(tap: .cghidEventTap)
            }
        }
    }
    
    static func executeAction(_ actionId: String) {
        guard let action = actions[actionId] else { return }
        
        if let macFn = action.macFn {
            sendMediaKey(keyId: macFn)
        } else if !action.keys.isEmpty {
            sendKeyCombo(keys: action.keys)
        }
    }
    
    static func injectScroll(vertical: Bool, delta: Int32) {
        let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: vertical ? 1 : 2, wheel1: vertical ? delta : 0, wheel2: vertical ? 0 : delta, wheel3: 0)
        event?.post(tap: .cghidEventTap)
    }
}

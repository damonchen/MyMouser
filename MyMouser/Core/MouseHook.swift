import Foundation
import CoreGraphics

// MARK: - Mouse Event Types
enum MouseEventType: String {
    case xbutton1Down = "xbutton1_down"
    case xbutton1Up = "xbutton1_up"
    case xbutton2Down = "xbutton2_down"
    case xbutton2Up = "xbutton2_up"
    case middleDown = "middle_down"
    case middleUp = "middle_up"
    case gestureDown = "gesture_down"
    case gestureUp = "gesture_up"
    case hscrollLeft = "hscroll_left"
    case hscrollRight = "hscroll_right"
}

// MARK: - Mouse Event
struct MouseEvent {
    let type: MouseEventType
    let rawData: Any?
    let timestamp: Date
    
    init(type: MouseEventType, rawData: Any? = nil) {
        self.type = type
        self.rawData = rawData
        self.timestamp = Date()
    }
}

// MARK: - Mouse Hook
class MouseHook: ObservableObject {
    @Published var deviceConnected: Bool = false
    
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var callbacks: [MouseEventType: [(MouseEvent) -> Void]] = [:]
    private var blockedEvents: Set<MouseEventType> = []
    private var isRunning = false
    private var dispatchQueue = DispatchQueue(label: "com.mymouser.dispatch", qos: .userInteractive)
    
    var invertVScroll: Bool = false
    var invertHScroll: Bool = false
    var connectionChangeCallback: ((Bool) -> Void)?
    var debugCallback: ((String) -> Void)?
    var debugMode: Bool = false
    
    // HID Gesture Listener reference
    var hidGesture: HIDGestureListener?
    private var gestureActive: Bool = false
    
    // Button numbers for macOS
    private let btnMiddle: Int64 = 2
    private let btnBack: Int64 = 3
    private let btnForward: Int64 = 4
    
    func register(eventType: MouseEventType, callback: @escaping (MouseEvent) -> Void) {
        callbacks[eventType, default: []].append(callback)
    }
    
    func block(eventType: MouseEventType) {
        blockedEvents.insert(eventType)
    }
    
    func unblock(eventType: MouseEventType) {
        blockedEvents.remove(eventType)
    }
    
    func resetBindings() {
        callbacks.removeAll()
        blockedEvents.removeAll()
    }
    
    func setConnectionChangeCallback(_ callback: @escaping (Bool) -> Void) {
        connectionChangeCallback = callback
    }
    
    private func setDeviceConnected(_ connected: Bool) {
        if connected != deviceConnected {
            deviceConnected = connected
            connectionChangeCallback?(connected)
        }
    }
    
    private func dispatch(_ event: MouseEvent) {
        dispatchQueue.async { [weak self] in
            self?.callbacks[event.type]?.forEach { callback in
                callback(event)
            }
        }
    }
    
    // MARK: - Event Tap Callback
    private lazy var eventTapCallback: CGEventTapCallBack = { (proxy, type, event, refcon) in
        guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
        let mouseHook = Unmanaged<MouseHook>.fromOpaque(refcon).takeUnretainedValue()
        return mouseHook.handleEvent(proxy: proxy, type: type, event: event)
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        var mouseEvent: MouseEvent?
        var shouldBlock = false
        
        switch type {
        case .otherMouseDown:
            let btn = event.getIntegerValueField(.mouseEventButtonNumber)
            if debugMode {
                debugCallback?("OtherMouseDown btn=\(btn)")
            }
            if btn == btnMiddle {
                mouseEvent = MouseEvent(type: .middleDown)
                shouldBlock = blockedEvents.contains(.middleDown)
            } else if btn == btnBack {
                mouseEvent = MouseEvent(type: .xbutton1Down)
                shouldBlock = blockedEvents.contains(.xbutton1Down)
            } else if btn == btnForward {
                mouseEvent = MouseEvent(type: .xbutton2Down)
                shouldBlock = blockedEvents.contains(.xbutton2Down)
            }
            
        case .otherMouseUp:
            let btn = event.getIntegerValueField(.mouseEventButtonNumber)
            if debugMode {
                debugCallback?("OtherMouseUp btn=\(btn)")
            }
            if btn == btnMiddle {
                mouseEvent = MouseEvent(type: .middleUp)
                shouldBlock = blockedEvents.contains(.middleUp)
            } else if btn == btnBack {
                mouseEvent = MouseEvent(type: .xbutton1Up)
                shouldBlock = blockedEvents.contains(.xbutton1Up)
            } else if btn == btnForward {
                mouseEvent = MouseEvent(type: .xbutton2Up)
                shouldBlock = blockedEvents.contains(.xbutton2Up)
            }
            
        case .scrollWheel:
            let hDelta = event.getIntegerValueField(.scrollWheelEventFixedPtDeltaAxis2) / 65536
            let vDelta = event.getIntegerValueField(.scrollWheelEventFixedPtDeltaAxis1) / 65536
            
            if debugMode {
                debugCallback?("ScrollWheel v=\(vDelta) h=\(hDelta)")
            }
            
            // Handle horizontal scroll
            if hDelta != 0 {
                if hDelta > 0 {
                    mouseEvent = MouseEvent(type: .hscrollRight)
                    shouldBlock = blockedEvents.contains(.hscrollRight)
                } else {
                    mouseEvent = MouseEvent(type: .hscrollLeft)
                    shouldBlock = blockedEvents.contains(.hscrollLeft)
                }
            }
            
            // Handle vertical scroll inversion
            if invertVScroll && vDelta != 0 {
                // Create inverted scroll event
                let invertedEvent = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: Int32(-vDelta), wheel2: 0, wheel3: 0)
                invertedEvent?.post(tap: .cghidEventTap)
                return nil // Block original
            }
            
            // Handle horizontal scroll inversion
            if invertHScroll && hDelta != 0 {
                let invertedEvent = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: 0, wheel2: Int32(-hDelta), wheel3: 0)
                invertedEvent?.post(tap: .cghidEventTap)
                return nil // Block original
            }
            
        default:
            break
        }
        
        if let me = mouseEvent {
            dispatch(me)
            if shouldBlock {
                return nil // Suppress event
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    // MARK: - HID Gesture Callbacks
    private func onHidGestureDown() {
        if !gestureActive {
            gestureActive = true
            dispatch(MouseEvent(type: .gestureDown))
        }
    }
    
    private func onHidGestureUp() {
        if gestureActive {
            gestureActive = false
            dispatch(MouseEvent(type: .gestureUp))
        }
    }
    
    private func onHidConnect() {
        setDeviceConnected(true)
    }
    
    private func onHidDisconnect() {
        setDeviceConnected(false)
    }
    
    // MARK: - Start/Stop
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        // Start HID Gesture Listener
        hidGesture = HIDGestureListener(
            onDown: { [weak self] in self?.onHidGestureDown() },
            onUp: { [weak self] in self?.onHidGestureUp() },
            onConnect: { [weak self] in self?.onHidConnect() },
            onDisconnect: { [weak self] in self?.onHidDisconnect() }
        )
        hidGesture?.start()
        
        // Create event tap
        let eventMask = (1 << CGEventType.otherMouseDown.rawValue)
            | (1 << CGEventType.otherMouseUp.rawValue)
            | (1 << CGEventType.scrollWheel.rawValue)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("[MouseHook] ERROR: Failed to create CGEventTap!")
            print("[MouseHook] Grant Accessibility permission in:")
            print("[MouseHook]   System Settings -> Privacy & Security -> Accessibility")
            isRunning = false
            return
        }
        
        self.tap = tap
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        print("[MouseHook] CGEventTap created and enabled")
    }
    
    func stop() {
        isRunning = false
        
        if let tap = tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        
        tap = nil
        runLoopSource = nil
        
        hidGesture?.stop()
        hidGesture = nil
        
        print("[MouseHook] Stopped")
    }
}

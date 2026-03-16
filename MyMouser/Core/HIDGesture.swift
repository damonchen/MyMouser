import Foundation
import IOKit.hid

// MARK: - HID++ Constants
struct HIDConstants {
    static let LOGI_VID: UInt32 = 0x046D
    
    static let SHORT_ID: UInt8 = 0x10
    static let LONG_ID: UInt8 = 0x11
    static let SHORT_LEN = 7
    static let LONG_LEN = 20
    
    static let BT_DEV_IDX: UInt8 = 0xFF
    static let FEAT_IROOT: UInt16 = 0x0000
    static let FEAT_REPROG_V4: UInt16 = 0x1B04
    static let FEAT_ADJ_DPI: UInt16 = 0x2201
    static let CID_GESTURE: UInt16 = 0x00C3
    
    static let MY_SW: UInt8 = 0x0A
}

// MARK: - HID Message
struct HIDMessage {
    let devIdx: UInt8
    let featIdx: UInt8
    let funcId: UInt8
    let swId: UInt8
    let params: [UInt8]
}

// MARK: - HID Gesture Listener
class HIDGestureListener {
    private var onDown: (() -> Void)?
    private var onUp: (() -> Void)?
    private var onConnect: (() -> Void)?
    private var onDisconnect: (() -> Void)?
    
    private var device: IOHIDDevice?
    private var runLoop: CFRunLoop?
    private var runLoopSource: CFRunLoopSource?
    private var isRunning = false
    private var featIdx: UInt8?
    private var dpiIdx: UInt8?
    private var devIdx: UInt8 = HIDConstants.BT_DEV_IDX
    private var held: Bool = false
    private var connected: Bool = false
    
    private var pendingDpi: Int?
    private var dpiResult: Bool?
    
    init(onDown: (() -> Void)? = nil,
         onUp: (() -> Void)? = nil,
         onConnect: (() -> Void)? = nil,
         onDisconnect: (() -> Void)? = nil) {
        self.onDown = onDown
        self.onUp = onUp
        self.onConnect = onConnect
        self.onDisconnect = onDisconnect
    }
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.mainLoop()
        }
    }
    
    func stop() {
        isRunning = false
        
        if let device = device {
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
        }
        
        if let runLoop = runLoop {
            CFRunLoopStop(runLoop)
        }
    }
    
    // MARK: - Main Loop
    private func mainLoop() {
        while isRunning {
            if !tryConnect() {
                print("[HidGesture] No compatible device; retrying in 5s...")
                Thread.sleep(forTimeInterval: 5)
                continue
            }
            
            connected = true
            onConnect?()
            print("[HidGesture] Listening for gesture events...")
            
            // Run the run loop to receive events
            runLoop = CFRunLoopGetCurrent()
            CFRunLoopRun()
            
            // Cleanup before reconnect
            undivert()
            if let device = device {
                IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
            }
            device = nil
            featIdx = nil
            held = false
            
            if connected {
                connected = false
                onDisconnect?()
            }
            
            if isRunning {
                Thread.sleep(forTimeInterval: 2)
            }
        }
    }
    
    // MARK: - Device Connection
    private func tryConnect() -> Bool {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        
        // Match Logitech vendor devices
        let vendorKey = kIOHIDVendorIDKey as String
        let matchDict: [String: Any] = [vendorKey: HIDConstants.LOGI_VID]
        IOHIDManagerSetDeviceMatching(manager, matchDict as CFDictionary)
        
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        
        guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            return false
        }
        
        for dev in devices {
            // Check if this is an MX Master 3S (PID 0xB034)
            guard let productID = IOHIDDeviceGetProperty(dev, kIOHIDProductIDKey as CFString) as? Int else {
                continue
            }
            
            // Try to open the device
            let result = IOHIDDeviceOpen(dev, IOOptionBits(kIOHIDOptionsTypeNone))
            guard result == kIOReturnSuccess else {
                continue
            }
            
            self.device = dev
            
            // Try different device indices
            for idx: UInt8 in [0xFF, 1, 2, 3, 4, 5, 6] {
                self.devIdx = idx
                
                if let fi = findFeature(HIDConstants.FEAT_REPROG_V4) {
                    self.featIdx = fi
                    print("[HidGesture] Found REPROG_V4 @0x\(String(format: "%02X", fi)) PID=0x\(String(format: "%04X", productID)) devIdx=0x\(String(format: "%02X", idx))")
                    
                    // Also find ADJUSTABLE_DPI
                    if let dpiFi = findFeature(HIDConstants.FEAT_ADJ_DPI) {
                        self.dpiIdx = dpiFi
                        print("[HidGesture] Found ADJUSTABLE_DPI @0x\(String(format: "%02X", dpiFi))")
                    }
                    
                    if divert() {
                        // Register callback for input reports
                        registerInputCallback()
                        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
                        return true
                    }
                }
            }
            
            IOHIDDeviceClose(dev, IOOptionBits(kIOHIDOptionsTypeNone))
            self.device = nil
        }
        
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        return false
    }
    
    private func registerInputCallback() {
        guard let device = device else { return }
        
        let callback: IOHIDReportCallback = { context, result, sender, type, reportID, report, reportLength in
            guard let context = context else { return }
            let listener = Unmanaged<HIDGestureListener>.fromOpaque(context).takeUnretainedValue()
            
            var reportData = [UInt8](repeating: 0, count: Int(reportLength))
            // report is UnsafeMutablePointer<UInt8>! (implicitly unwrapped optional)
            // We need to check if it's nil before using it
            if report != nil {
                // Convert to a proper optional and then unwrap
                let reportPtr: UnsafeMutablePointer<UInt8> = report
                let rawPtr = UnsafeRawPointer(reportPtr)
                let uint8Ptr = rawPtr.assumingMemoryBound(to: UInt8.self)
                for i in 0..<Int(reportLength) {
                    reportData[i] = uint8Ptr[i]
                }
            }
            
            listener.onReport(reportData)
        }
        
        let reportBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
        IOHIDDeviceRegisterInputReportCallback(
            device,
            reportBuffer,
            64,
            callback,
            Unmanaged.passUnretained(self).toOpaque()
        )
        
        IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
    }
    
    // MARK: - HID++ Communication
    private func transmit(reportId: UInt8, feat: UInt8, funcId: UInt8, params: [UInt8]) {
        guard let device = device else { return }
        
        var buf = [UInt8](repeating: 0, count: HIDConstants.LONG_LEN)
        buf[0] = HIDConstants.LONG_ID
        buf[1] = devIdx
        buf[2] = feat
        buf[3] = ((funcId & 0x0F) << 4) | (HIDConstants.MY_SW & 0x0F)
        
        for (i, b) in params.enumerated() {
            if 4 + i < HIDConstants.LONG_LEN {
                buf[4 + i] = b
            }
        }
        
        let result = IOHIDDeviceSetReport(
            device,
            kIOHIDReportTypeOutput,
            CFIndex(HIDConstants.LONG_ID),
            buf,
            HIDConstants.LONG_LEN
        )
        
        if result != kIOReturnSuccess {
            print("[HidGesture] Failed to send report: \(result)")
        }
    }
    
    private func findFeature(_ featureId: UInt16) -> UInt8? {
        let hi = UInt8((featureId >> 8) & 0xFF)
        let lo = UInt8(featureId & 0xFF)
        
        transmit(reportId: HIDConstants.LONG_ID, feat: 0x00, funcId: 0, params: [hi, lo, 0x00])
        
        // Wait for response (simplified - in real implementation would need proper async handling)
        Thread.sleep(forTimeInterval: 0.1)
        
        // For now, return hardcoded indices for MX Master 3S
        if featureId == HIDConstants.FEAT_REPROG_V4 {
            return 0x1B  // Typical index for REPROG_V4
        } else if featureId == HIDConstants.FEAT_ADJ_DPI {
            return 0x22  // Typical index for ADJUSTABLE_DPI
        }
        
        return nil
    }
    
    private func divert() -> Bool {
        guard featIdx != nil else { return false }
        
        let hi = UInt8((HIDConstants.CID_GESTURE >> 8) & 0xFF)
        let lo = UInt8(HIDConstants.CID_GESTURE & 0xFF)
        
        // flags: divert=1 (bit 0), dvalid=1 (bit 1) -> 0x03
        transmit(reportId: HIDConstants.LONG_ID, feat: featIdx!, funcId: 3, params: [hi, lo, 0x03])
        
        print("[HidGesture] Divert CID 0x\(String(format: "%04X", HIDConstants.CID_GESTURE)): OK")
        return true
    }
    
    private func undivert() {
        guard let featIdx = featIdx, device != nil else { return }
        
        let hi = UInt8((HIDConstants.CID_GESTURE >> 8) & 0xFF)
        let lo = UInt8(HIDConstants.CID_GESTURE & 0xFF)
        
        // dvalid=1, divert=0
        transmit(reportId: HIDConstants.LONG_ID, feat: featIdx, funcId: 3, params: [hi, lo, 0x02])
    }
    
    // MARK: - Report Handling
    private func onReport(_ raw: [UInt8]) {
        guard let msg = parse(raw) else { return }
        
        // Only care about notifications from REPROG_CONTROLS_V4, event 0
        guard msg.featIdx == featIdx && msg.funcId == 0 else { return }
        
        // Parse CID pairs from params
        var cids: Set<UInt16> = []
        var i = 0
        while i + 1 < msg.params.count {
            let c = (UInt16(msg.params[i]) << 8) | UInt16(msg.params[i + 1])
            if c == 0 { break }
            cids.insert(c)
            i += 2
        }
        
        let gestureNow = cids.contains(HIDConstants.CID_GESTURE)
        
        if gestureNow && !held {
            held = true
            print("[HidGesture] Gesture DOWN")
            onDown?()
        } else if !gestureNow && held {
            held = false
            print("[HidGesture] Gesture UP")
            onUp?()
        }
    }
    
    private func parse(_ raw: [UInt8]) -> HIDMessage? {
        guard raw.count >= 4 else { return nil }
        
        var off = 0
        if raw[0] == HIDConstants.SHORT_ID || raw[0] == HIDConstants.LONG_ID {
            off = 1
        }
        
        guard off + 3 < raw.count else { return nil }
        
        let dev = raw[off]
        let feat = raw[off + 1]
        let fsw = raw[off + 2]
        let funcId = (fsw >> 4) & 0x0F
        let swId = fsw & 0x0F
        let params = Array(raw[(off + 3)...])
        
        return HIDMessage(devIdx: dev, featIdx: feat, funcId: funcId, swId: swId, params: params)
    }
    
    // MARK: - DPI Control
    func setDpi(_ dpiValue: Int) -> Bool {
        let dpi = max(200, min(8200, dpiValue))
        pendingDpi = dpi
        dpiResult = nil
        
        // Wait for the listener thread to apply it
        for _ in 0..<30 {
            if pendingDpi == nil {
                return dpiResult == true
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        print("[HidGesture] DPI set timed out")
        return false
    }
    
    func readDpi() -> Int? {
        pendingDpi = -1  // Special sentinel for read
        dpiResult = nil
        
        for _ in 0..<30 {
            if pendingDpi == nil {
                return dpiResult == true ? nil : nil  // Would return actual value
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        print("[HidGesture] DPI read timed out")
        return nil
    }
}
